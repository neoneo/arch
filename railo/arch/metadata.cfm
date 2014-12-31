<!--- JSON deserialize results in linked structs. --->
<cfsavecontent variable="json">
{
	"+": {"args": {"a": "real", "b": "real"}, "result": "real", "pos": "infix", "assoc": "left"},
	"-": {"args": {"a": "real", "b": "real"}, "result": "real", "pos": "infix", "assoc": "left"},
	"*": {"args": {"a": "real", "b": "real"}, "result": "real", "pos": "infix", "assoc": "left"},
	"/": {"args": {"a": "real", "b": "real"}, "result": "real", "pos": "infix", "assoc": "left"},
	"^": {"args": {"a": "real", "b": "real"}, "result": "real", "assoc": "right"},
	"mod": {"args": {"a": "real", "b": "real"}, "result": "real", "assoc": "right"},
	"!": {"args": {"n": "integer"}, "result": "integer", "pos": "postfix"},
	"sqrt": {"args": {"x": "real"}, "result": "real", "pos": "prefix"},
	"=": {"args": {"a": "real", "b": "real"}, "result": "boolean", "pos": "infix", "assoc": "left"},
	"~=": {"args": {"a": "real", "b": "real"}, "result": "boolean", "pos": "infix", "assoc": "left"},
	"<": {"args": {"a": "real", "b": "real"}, "result": "boolean", "pos": "infix", "assoc": "left"},
	">": {"args": {"a": "real", "b": "real"}, "result": "boolean", "pos": "infix", "assoc": "left"},
	"<=": {"args": {"a": "real", "b": "real"}, "result": "boolean", "pos": "infix", "assoc": "left"},
	">=": {"args": {"a": "real", "b": "real"}, "result": "boolean", "pos": "infix", "assoc": "left"},
	"/\\": {"args": {"p": "boolean", "q": "boolean"}, "result": "boolean", "pos": "infix", "assoc": "left"},
	"\\/": {"args": {"p": "boolean", "q": "boolean"}, "result": "boolean", "pos": "infix", "assoc": "left"},
	"~": {"args": {"p": "boolean"}, "result": "boolean", "pos": "prefix"}
}
</cfsavecontent>
<cfset this.metadata = DeserializeJSON(json)>