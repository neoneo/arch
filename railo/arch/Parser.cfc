component {

	this.open = ["BEGIN", "PARENOPEN", "BRACKETOPEN", "BRACEOPEN", "BAROPEN"]
	this.close = ["END", "PARENCLOSE", "BRACKETCLOSE", "BRACECLOSE", "BARCLOSE"]
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

			for (var node in expression) {
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
				- matrices and vectors (TODO)
			*/
			var i = 1
			var nodes = []
			var length = expression.len()
			while (i <= length) {
				var current = expression[i]
				if (i + 1 <= length) {
					var next = expression[i + 1]

					if ("NUMBER VARIABLE PARENOPEN" contains current.type && "NUMBER VARIABLE PARENOPEN" contains next.type) {
						var group = {
							type: "GROUP",
							expressions: [
								[current]
							],
							line: current.line,
							column: current.column,
							source: 124
						}

						i += 1
						current = next
						while (i <= length && "NUMBER VARIABLE PARENOPEN" contains current.type) {
							group.expressions[1].append(current)
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

	public Array function isolate(required Array expressions) {
		return arguments.expressions.map(function (expression) {
			return this.isolate2(arguments.expression);
		});
	}

	/**
	 * Isolates functions that are already in prefix into their own groups.
	 */
	private Array function isolate2(required Array expression, Numeric consume = -1) {
		var nodes = []

		while (!arguments.expression.isEmpty() && (arguments.consume == -1 || arguments.consume >= nodes.len())) {
			var node = arguments.expression.first()
			arguments.expression.deleteAt(1)

			// For some of the following operations, we need the next node.
			var next = !arguments.expression.isEmpty() ? arguments.expression.first() : null;

			/*
				First, group postfix functions with their arguments. Postfix functions can have at most arity 1.
				Do this regardless of the mode (infix / prefix) we're in. Postfix functions cannot be used as prefix
				functions, because when the function name is alphanumeric, a space is required to separate it.
			*/
			if (next !== null && next.type == "FUNCTION" && this.metadata[next.name].pos == "postfix") {
				// The current node must be an operand.
				if ("LAMBDA ASSIGN CHAIN" does not contain node.type) {
					nodes.append({
						type: "GROUP",
						line: node.line,
						column: node.column,
						expressions: [
							[node, next]
						],
						source: 183
					})
				}
			}

			/*
				Insert multiplication operators if:
				1. We are in infix mode.
				2. The previous node is not function, unaryminus, lambda, assign or chain.
				3. The current node is not space, lambda, assign, chain or a function with arity 2.
			*/
			if (arguments.consume == -1) {
				if (!nodes.isEmpty() && "FUNCTION UNARYMINUS LAMBDA ASSIGN CHAIN" does not contain nodes.last().type) {
					if ("SPACE FUNCTION LAMBDA ASSIGN CHAIN" does not contain node.type || node.type == "FUNCTION" && this.metadata[node.name].args.len() != 2) {
						nodes.append({
							type: "FUNCTION",
							name: "*",
							line: node.line,
							column: node.column
						})
					}
				}
			}

			if (node.type == "FUNCTION") {
				/*
					Check for unary - or +. This is the case if we have a - or + and:
					1. The next node is not a space, and
					2a. We are in prefix mode, or
					2b. There either is no previous node, or it is function, lambda or assign.
				*/
				if ("-+" contains node.name) {
					// In infix as well as prefix mode, the next node may not be a space.
					if (next !== null && next.type != "SPACE") {
						// Now, the function is unary if we're in prefix mode or condition 2b above applies.
					 	// The previous node is now the last node in the nodes array.
					 	if (arguments.consume > -1 || nodes.isEmpty() || "FUNCTION LAMBDA ASSIGN" contains nodes.last().type) {
							// Ignore unary +.
							if (node.name == "-") {
								node.type = "UNARYMINUS"
								// If we're in prefix mode, group the node and the next one.
								if (arguments.consume > -1) {
									// Consume the next node.
									arguments.expression.deleteAt(1)
									// TODO: fix code duplication
									if ("PARENOPEN GROUP BEGIN" contains next.type) {
										next.expressions = this.isolate(next.expressions)
									}
									nodes.append({
										type: "GROUP",
										expressions: [
											[node, next]
										],
										line: node.line,
										column: node.column,
										source: 229
									})
								} else {
									// Otherwise, leave as is. We're in infix, so operator precedence has to be taken into account.
									nodes.append(node)
								}
							}
							continue;
					 	}
					}
				}

				var arity = this.metadata[node.name].args.len()
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
						column: node.column,
						source: 242
					}
					// Consume the arguments. This may consume more nodes than there are arguments.
					var args = this.isolate2(arguments.expression, arity)
					group.expressions = args.prepend(node) // Prepend the function to the arguments.
					nodes.append(group)
				} else {
					// The function is not in prefix, just add it.
					nodes.append(node)
				}

			} else if ("LAMBDA ASSIGN CHAIN" contains node.type) {
				/*
					These nodes may not be used as prefix operators. This is the case if:
					- We are in prefix mode, or
					- This is the first node in the expression.
				*/
				if (arguments.consume > -1 || nodes.isEmpty()) {
					Throw("Operator '#node.lexeme#' cannot be used as prefix operator", "ParseException", "{line: #node.line#, column: #node.column#}");
				}

				nodes.append(node)

			} else if (node.type != "SPACE") {
				if ("PARENOPEN GROUP BEGIN" contains node.type) {
					node.expressions = this.isolate(node.expressions); // No consume parameter, so start in infix mode.
				}
				nodes.append(node)
			}
		}

		return nodes;
	}

}