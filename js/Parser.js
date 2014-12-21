var TYPE = 0, SYMBOL = 1, LINE = 3, COLUMN = 4;

var Parser = Class.extend({

	blocks: function (tokens) {
		var nodes = []

		var token, node;
		while (token = tokens.shift()) {
			node = new Node(token);
			if (token[TYPE] === "BEGIN") {
				_.forEach(this.blocks(tokens), function (childNode) {
					node.add(childNode);
				});
			} else if (token[TYPE] === "END") {
				return nodes;
			}

			nodes.push(node);
		}

		return nodes;
	}
})

var Node = Class.extend({

	constructor: function (token) {
		this._token = token[SYMBOL];
		this._children = []
	},

	add: function (node) {
		this._children.push(node)
	}

})