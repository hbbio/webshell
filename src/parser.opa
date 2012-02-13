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
    parser { case Rule.ws res=p Rule.ws: res }
  }

  `(` = ws(parser { case "(": void })
  `)` = ws(parser { case ")": void })

  term = parser {
    case f = {ws(Rule.float)}: f
    case `(` ~expr `)`: expr
  }

  factor = parser {
    case ~term "*" ~factor : term * factor
    case ~term "/" ~factor : term / factor
    case ~term : term
  }

  expr = parser {
    case ~factor "+" ~expr : factor + expr
    case ~factor "-" ~expr : factor - expr
    case ~factor : factor
  }

  search = ws(parser { case "search" : void })
  set = ws(parser { case "set" : void })
  next = ws(parser { case "next" : void })
  prev = ws(parser { case "prev" : void })
  page = ws(parser { case "page" : void })

  args = parser {
    case txt=(.*) : List.map(String.trim,String.explode(" ",Text.to_string(txt)))
  }

  shell = parser {
    case search ~args : { search:args }
    case set ~args : { set:args }
    case next : { next }
    case prev : { prev }
    case page pagenum={ws(Rule.natural)} : { ~pagenum }
    case command={ws(Rule.ident)} arg={ws(Rule.ident)} : { ~command, ~arg }
    case ~expr : {value: expr}
  }

  function compute(s) {
    match (Parser.try_parse(expr, s)) {
      case {some: result}: "{result}";
      case {none}: "unknown";
    }
  }
}
