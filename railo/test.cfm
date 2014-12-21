<cfsavecontent variable="code">
abcformule := (a, b, c) ->

	# bereken de discriminant

	D := begin
		b ^ 2 - 4ac
	end

	# definieer een functie die een van de oplossingen berekent
	oplossing := (teken) -> (-b + teken sqrt(D)) / 2a

	# geef de vector met de oplossingen terug
	if D >= 0 then
		[oplossing(1), oplossing(-1)]
	else
		[undefined, undefined]
	end

end

grootste_oplossing := abcformule(1, 2, 3) fold using:
	(x, result) ->
		if x > result then x else result
	end:
	with -infinity
</cfsavecontent>
<!--- <cfsavecontent variable="code">
a:=fold array using:
	(acc,x)->acc+x
</cfsavecontent> --->
<cfscript>
	l = new arch.Lexer()
	p = new arch.Parser()
	tokens = l.tokenize(code)
	// dump(tokens)
	// exit;

	nodes = p.group(tokens)
	// This should be an array of length 1.
	dump(nodes)
</cfscript>