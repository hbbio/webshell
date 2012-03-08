// license: AGPL
// (c) MLstate, 2011, 2012
// author: Adam Koprowski, Henri Binsztok

module Calc {

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

  Service.spec spec =
    { initial_state: void,
      function parse_cmd(_) {
        parser {
        case ~expr : Service.respond_with(<>= {expr}</>)
        }
      }
    }

}


