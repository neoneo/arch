<cfsavecontent variable="code">
abcformule := (a, b,
	c) ->

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

end # einde van de functie
<!---
grootste_oplossing := abcformule(1, 2, 3) fold using:
	(x, result) ->
		if x > result then x else result
	end,
	with -infinity --->
</cfsavecontent>
<cfsavecontent variable="code">
<!--- - -a(a + b) * x ^ 2 3 --->
x := (-b + teken sqrt (b ^ 2 -4ac)) / 2a
<!--- sin -x --->
<!--- sin (a + b)(c + d) --->
<!--- sin 2x --->
<!--- sin 2 x = (sin 2) * x --->
<!--- a := sqrt (b ^ 2 + c ^ 2 - 2 b c cos alpha) --->

</cfsavecontent>
<cfscript>
	l = new arch.Lexer()
	tokens = l.tokenize(code)
	// dump(tokens)
	// exit;

	p = new arch.Parser()
	nodes = p.group(tokens)
	nodes = p.split(nodes)
	p.identify(nodes)
	// This should be an array of length 1.
	nodes = p.isolate(nodes)
	dump(nodes)
</cfscript>