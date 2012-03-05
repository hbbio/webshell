// license: AGPL
// (c) MLstate, 2011, 2012
// author: Adam Koprowski

 // service response to a command
type Service.response('t) =
  { xhtml response, 't new_state }

 // specification of a single service
type Service.spec('t) =
  { 't initial_state,
    ('t -> Parser.general_parser(Service.response('t))) parse_cmd
  }

 // implementation of a service
abstract type Service.t =
  Cell.cell(string, {cannot_handle} or {xhtml response})

server module Service {

   // builds a service from its specification
  function Service.t make(Service.spec('t) spec) {
    function process_cmd(state, cmd) {
      cmd_parser = spec.parse_cmd(state)
      match (Parser.try_parse(cmd_parser, cmd)) {
      case {some: res}:
        { return: {response: res.response},
          instruction: {set: res.new_state}
        }
      default:
        { return: {cannot_handle},
          instruction: {unchanged}
        }
      }
    }
    Cell.make(spec.initial_state, process_cmd)
  }

}

// implementation of a system (consisting of a bunch of services)
abstract type System.t = list(Service.t)

server module System {

  function System.t build(list(Service.t) services) {
    services
  }

  function xhtml process(System.t sys, string cmd) {
    recursive function aux(services) {
      match (services) {
      case []:
          <>Unknown command</>
      case [x | xs]:
        match (Cell.call(x, cmd)) {
        case ~{response}:
          response
        default:
          aux(xs)
        }
      }
    }
    aux(sys)
  }

}
