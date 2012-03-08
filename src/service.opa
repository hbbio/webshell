// license: AGPL
// (c) MLstate, 2011, 2012
// author: Adam Koprowski

type Service.response =
  { xhtml outcome } or { string redirect }

type Service.state_change('state) =
  { no_change } or { 'state new_state }

 // service response to a command
type Service.outcome('state) =
  { Service.response response, Service.state_change('state) state_change }

 // specification of a single service
type Service.spec('state) =
  { 'state initial_state,
    ('state -> Parser.general_parser(Service.outcome('state))) parse_cmd
  }

type Service.cmd_executor =
  string -> {cannot_handle} or {Service.response response}

type Service.fun_executor('state) =
  ('state -> 'state) -> void

 // implementation of a service
type Service.t('state) =
  { Service.cmd_executor cmd_executor,
    Service.fun_executor('state) fun_executor
  }

server module Service {

  private function execute_cmd(service, state, cmd) {
    cmd_parser = service.spec.parse_cmd(state)
    match (Parser.try_parse(cmd_parser, cmd)) {
    case {some: res}:
      instruction =
        match (res.state_change) {
        case {no_change}: {unchanged}
        case {new_state: state}: {set: state}
        }
      { return: {response: res.response}, ~instruction }
    default:
      { return: {cannot_handle},
        instruction: {unchanged}
      }
    }
  }

  private function execute_fun(state, fun) {
    new_state = fun(state)
    { return: {cannot_handle},
      instruction: {set: new_state}
    }
  }

  private function process_request(service, state, cmd) {
    match (cmd) {
    case {execute_fun: fun}: execute_fun(state, fun)
    case {execute_cmd: cmd}: execute_cmd(service, state, cmd)
    }
  }

   // builds a service from its specification
  function Service.t make({Service.spec spec, ...} service) {
    cell = Cell.make(service.spec.initial_state, process_request(service, _, _))
    { cmd_executor: function (cmd) { Cell.call(cell, {execute_cmd: cmd}) },
      fun_executor: function (fun) { _ = Cell.call(cell, {execute_fun: fun}); void }
    }
  }

  function respond_with(xhtml) {
    { state_change: {no_change},
      response: {outcome: xhtml}
    }
  }

}

// implementation of a system (consisting of a bunch of services)
abstract type System.t = list(Service.cmd_executor)

server module Shell {

  function System.t build(list(Service.cmd_executor) services) {
    services
  }

  function xhtml execute(System.t sys, string cmd) {
    recursive function aux(services) {
      match (services) {
      case []:
          <>Unknown command</>
      case [service | services]:
        match (service(cmd)) {
        case {response: {~outcome}}:
          outcome
        case {response: {~redirect}}:
          Client.goto(redirect);
          <></>
        default:
          aux(services)
        }
      }
    }
    aux(sys)
  }

}
