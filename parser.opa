// license: AGPL
// (c) MLstate, 2011
// author: Adam Koprowski, Henri Binsztok

module Calc {

	function ws(p) {
	parser
	| Rule.ws res=p Rule.ws -> res
	}

	`(` = ws(parser | "(" -> void)
	`)` = ws(parser | ")" -> void)

	term = parser
	| f = {ws(Rule.float)} -> f
	| `(` ~expr `)` -> expr

	factor = parser
	| ~term "*" ~factor -> term * factor
	| ~term "/" ~factor -> term / factor
	| ~term -> term

	expr = parser
	| ~factor "+" ~expr -> factor + expr
	| ~factor "-" ~expr -> factor - expr
	| ~factor -> factor
	
	shell = parser
	| command={ws(Rule.ident)} arg={ws(Rule.ident)} -> { ~command, ~arg }
	| ~expr -> {value: expr}
  	
	function compute(s) {
		match (Parser.try_parse(expr, s)) {
			case {some: result}: "{result}";
			case {none}: "unknown";
    	}
  	}
}
