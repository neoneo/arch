component {

	this.open = ["BEGIN", "PARENOPEN", "BRACKETOPEN", "BRACEOPEN", "PIPEOPEN"]
	this.close = ["END", "PARENCLOSE", "BRACKETCLOSE", "BRACECLOSE", "PIPECLOSE"]
	this.symbols = ["end", ")", "]", "}", "|"]

	include template="metadata.cfm";

	/**
	 * Group the tokens in a tree of nodes, where each branch represents a block.
	 */
	public Array function group(required Array tokens) {

		var nodes = []

		do {
			var token = arguments.tokens.first()
			arguments.tokens.deleteAt(1)

			var index = this.open.find(token.type)
			if (index > 0) {
				token.children = this.group(arguments.tokens)
				if (token.children.isEmpty()) {
					Throw("Premature end of block", "ParseException", "{line: #token.line#, column: #token.column#}");
				} else {
					// The close of the block should be of the same type.
					var closeToken = token.children.last()
					if (close.find(closeToken.type) != index) {
						Throw("Matching #token.lexeme#, expected #this.symbols[index]# but received #closeToken.lexeme#", "ParseException", "{line: #token.line#, column: #token.column#}");
					}
					token.children.delete(closeToken)
				}
			}

			nodes.append(token);

			if (this.close.find(token.type) > 0) {
				break;
			}

		} while (!arguments.tokens.isEmpty());

		return nodes;
	}

	/**
	 * Split blocks in expressions at newlines.
	 */
	public Array function split(required Array nodes) {

		var expressions = []
		var expression = []

		for (var node in arguments.nodes) {
			if (node.type == "NEWLINE") {
				expressions.append(expression)
				expression = []
			} else {
				if (node.keyExists("children")) {
					node.expressions = this.split(node.children)
					node.delete("children")
				}
				expression.append(node)
			}
		}
		if (!expression.isEmpty()) {
			expressions.append(expression)
		}

		return expressions;
	}

	// Vanaf hier hebben we een scope nodig, maar dat komt later.

	/**
	 * Identifies all identifiers and labels them accordingly.
	 */
	public void function identify(required Array expressions) {
		// For now assume unknown identifiers are variables. TODO: get from the scope
		var index = 1 // Expression index.
		for (var expression in arguments.expressions) {
			var length = expression.len()
			// var i = 0 // Node index.
			for (var node in expression) {
				// i += 1
				node.name = node.lexeme
				if (node.type == "OPERATOR") {
					node.type = "FUNCTION"
				} else if (node.type == "IDENTIFIER") {
					if (this.metadata.keyExists(node.name)) {
						node.type = "FUNCTION"
					} else {
						node.type = "VARIABLE"
					}
				}

				if (node.keyExists("expressions")) {
					this.identify(node.expressions)
				}
			}

			/*
				Group implicit multiplication if 2 operands are not separated by a space:
				- number variable: 4a
				- groups: (a+b)(c+d)
				- number group: 4(a+b)
				- variable variable: ab (TODO)
			*/
			var i = 1
			var nodes = []
			while (i <= length) {
				var current = expression[i]
				if (i + 1 <= length) {
					var next = expression[i + 1]

					if ("NUMBER VARIABLE PARENOPEN" contains current.type && "NUMBER VARIABLE PARENOPEN" contains next.type) {
						var group = {
							type: "GROUP",
							expression: [current],
							line: current.line,
							column: current.column,
							lexeme: ""
						}

						i += 1
						current = next
						while (i <= length && "NUMBER VARIABLE PARENOPEN" contains current.type) {
							group.expression.append(current)
							i += 1
							if (i <= length) {
								current = expression[i]
							}
						}

						nodes.append(group)
					}
				}

				// If the previous step has not consumed all nodes, the current node is not some operand.
				if (i <= length) {
					nodes.append(current)
				}

				i += 1
			}

			arguments.expressions[index] = nodes
			index += 1
		}

	}

	/**
	 * Isolates functions that are already in prefix into their own groups.
	 */
	public Array function isolate(required Array expression, Numeric consume = -1) {

		var nodes = []

		while (!arguments.expression.isEmpty() && (arguments.consume == -1 || arguments.consume >= nodes.len())) {
			var node = arguments.expression.first()
			arguments.expression.deleteAt(1)

			/*
				First, insert multiplication operators if:
				1. We are in infix mode.
				2. The previous node is not function, lambda or assign.
				3. The next node is not lambda, assign or a function with arity 2.
			*/
			if (arguments.consume == -1) {
				if (!nodes.isEmpty() && "FUNCTION LAMBDA ASSIGN" does not contain nodes.last().type) {
					if (!arguments.expression.isEmpty()) {
						var next = arguments.expression.first()
						if ("FUNCTION LAMBDA ASSIGN" does not contain next.type || next.type == "FUNCTION" && this.metadata[next.name].args.len() != 2) {
							nodes.append({
								type: "FUNCTION",
								name: "*",
								line: node.line,
								column: node.column
							})
						}
					}
				}
			}

			if (node.type == "FUNCTION") {
				/*
					Check for unary - or +. This is the case if:
					1. The next node is not a space, and
					2a. We are in prefix mode, or
					2b. There either is no previous node, or it is function, lambda or assign.
				*/
				var arity = 1 // In case of unary -. We can overwrite this later if necessary.
				if ("-+" contains node.name) {
					// In infix as well as prefix mode, the next node may not be a space.
					if (!arguments.expression.isEmpty() && arguments.expression.first().type != "SPACE") {
						// Now, the function is unary if we're in prefix mode or condition 2b above applies.
					 	// The previous node is now the last node in the nodes array.
					 	if (arguments.consume > -1 || nodes.isEmpty() || "FUNCTION LAMBDA ASSIGN" contains nodes.last().type) {
							// Ignore unary +.
							if (node.name == "+") {
								continue;
							}
							node.type = "UNARY"
					 	}
					}
				} else {
					arity = this.metadata[node.name].args.len()
				}
				/*
					The function is in prefix if:
					- We are in prefix mode already, or:
					- This is the first node in the expression, or:
					- This is a function with arity not 2.
				*/
				if (arguments.consume > -1 || nodes.isEmpty() || arity != 2) {
					var group = {
						type: "GROUP",
						line: node.line,
						column: node.column
					}
					// Consume the arguments. This may consume more nodes than there are arguments.
					var args = this.isolate(arguments.expression, arity)
					group.expressions = args.prepend(node) // Prepend the function to the arguments.
					nodes.append(group)
				} else {
					// The function is not in prefix, just add it.
					nodes.append(node)
				}

			} else if ("LAMBDA ASSIGN" contains node.type) {
				// If, for whatever reason, these nodes are already in prefix, treat them as binary functions that consume the whole expression.
				// We can do this because these operators have lowest precedence when in infix. But in general, using these operators in prefix would be bad practice.
				/*
					These nodes are in prefix if:
					- We are in prefix mode, or
					- This is the first node in the expression.
				*/
				if (arguments.consume > -1 || nodes.isEmpty()) {
					var group = {
						type: "GROUP",
						line: node.line,
						column: node.column
					}
					if (arguments.expression.len() < 2) {
						Throw("Operator '#node.name#' requires 2 operands", "ParseException");
					}
					// The next node is the variable (assign) or the arguments (lambda).
					var operand = arguments.expression.first()
					arguments.expression.deleteAt(1)
					// The remainder is the value or the function body respectively.
					var body = this.isolate(arguments.expression)

					group.expressions = [node, operand, body]
					nodes.append(group)
				} else {
					nodes.append(node)
				}

			} else if (node.type != "SPACE") {
				if ("PARENOPEN GROUP" contains node.type) {
					node.expressions = node.expressions.map(function (expression) {
						return this.isolate(arguments.expression); // No consume parameter, so start in infix mode.
					})
				}
				nodes.append(node)
			}
		}

		return nodes;
	}

}