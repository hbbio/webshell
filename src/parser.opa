// license: AGPL
// (c) MLstate, 2011, 2012
// author: Adam Koprowski, Henri Binsztok

client module Calc {

  function int_of_string(string str) {
    (option(int)) Parser.try_parse(Rule.integer, str);
  }

  function nat_of_string(string str) {
    (option(int)) Parser.try_parse(Rule.natural, str);
  }

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

  search = ws(parser | "search" -> void)
  set = ws(parser | "set" -> void)
  next = ws(parser | "next" -> void)
  prev = ws(parser | "prev" -> void)
  page = ws(parser | "page" -> void)

  args = parser | txt=(.*) -> List.map(String.trim,String.explode(" ",Text.to_string(txt)))

  shell = parser
  | search ~args -> { search:args }
  | set ~args -> { set:args }
  | next -> { next }
  | prev -> { prev }
  | page pagenum={ws(Rule.natural)} -> { ~pagenum }
  | command={ws(Rule.ident)} arg={ws(Rule.ident)} -> { ~command, ~arg }
  | ~expr -> {value: expr}

  function compute(s) {
    match (Parser.try_parse(expr, s)) {
      case {some: result}: "{result}";
      case {none}: "unknown";
    }
  }
}
