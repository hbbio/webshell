// license: AGPL
// (c) MLstate, 2011, 2012
// author: Adam Koprowski

type Service.response =
  { xhtml outcome } or { string redirect }

type Service.state_change('state) =
  { no_change } or { 'state new_state }

 // service response to a command
type Service.outcome('state) =
  { Service.response response,
    Service.state_change('state) state_change
  }

// meta-data about the service (for help)
type Service.metadata =
  { string id,
    string description,
    list({string cmd, string description}) cmds
  }

 // specification of a single service
type Service.spec('state) =
  { 'state initial_state,
    ('state -> Parser.general_parser(Service.outcome('state))) parse_cmd,
    Service.metadata metadata
  }

type Service.cmd_executor =
  string -> {cannot_handle} or {Service.response response}

type Service.fun_executor('state) =
  ('state -> 'state) -> void

type Service.handler =
  { Service.cmd_executor cmd_executor,
    Service.metadata metadata
  }

 // implementation of a service
type Service.t('state) =
  { Service.handler handler,
    Service.fun_executor('state) fun_executor
  }

server module Service {

  private function execute_cmd(service, ctx, cmd) {
    cmd_parser = UserContext.execute(service.parse_cmd, ctx)
    match (Parser.try_parse(cmd_parser, cmd)) {
    case {some: res}:
      match (res.state_change) {
      case {no_change}:
        void
      case {new_state: new_state}:
        UserContext.change(function (_) { new_state }, ctx)
      };
      {response: res.response}
    case {none}:
      {cannot_handle}
    }
  }

   // builds a service from its specification
  function Service.t make({Service.spec spec, ...} service) {
    state = UserContext.make(service.spec.initial_state)
    handler =
      { metadata: service.spec.metadata,
        cmd_executor: execute_cmd(service.spec, state, _)
      }
    fun_executor = UserContext.change(_, state)
    ~{handler, fun_executor}
  }

  function respond_with(xhtml) {
    { state_change: {no_change},
      response: {outcome: xhtml}
    }
  }

}

// implementation of a system (consisting of a bunch of services)
abstract type System.t = list(Service.handler)

server module Shell {

  function System.t build(list(Service.handler) services) {
    services
  }

  function xhtml execute(System.t sys, string cmd) {
    recursive function aux(services) {
      match (services) {
      case []:
          <>Unknown command</>
      case [service | services]:
        match (service.cmd_executor(cmd)) {
        case {response: {~outcome}}:
          outcome
        case {response: {~redirect}}:
          Client.goto(redirect);
          <></>
        case {cannot_handle}:
          aux(services)
        }
      }
    }
    aux([core_handler(sys) | sys])
  }

  private function print_generic_help(mods) {
    function present_module(mod) {
      <li><strong>{mod.id}</>: {mod.description}</>
    }
    <>Use: '<strong>help module</>' to get help about using given module. Available modules:
    <ul>{List.map(present_module, mods)}</>
    </>
  }

  private function print_help_for(mods, mod_name) {
    function show_cmd(cmd) {
        <li><strong>{cmd.cmd}</>: {cmd.description}</>
    }
    function show_help(mod) {
      <>
        <strong>{mod.id}</>: {mod.description}
        <ul>{List.map(show_cmd, mod.cmds)}</>
      </>
    }
    function good_module(m) { m.id == mod_name }
    match (List.find(good_module, mods)) {
    case {some: mod}: show_help(mod)
    default:
      all_modules = List.map(_.id, mods)
      <>Unknown module: '{mod_name}'. Available modules: {List.to_string_using("", "", ", ", all_modules)}</>
    }
  }

  private function core_parser(mods) {
    parser {
    case "help": print_generic_help(mods)
    case "help" Rule.ws mod=(.*): print_help_for(mods, Text.to_string(mod))
    case "clear":
      LineEditor.clear();
      #terminal_prev = <></>;
      <></>
    }
  }

  private function core_executor(mods)(string cmd) {
    match (Parser.try_parse(core_parser(mods), cmd)) {
    case {some: res}: {response: {outcome: res}}
    default: {cannot_handle}
    }
  }

  private function core_handler(mods) {
    metadata =
      { id: "core",
        description: "Core shell functionality",
        cmds: [ { cmd: "clear",         description: "Clear the shell screen" },
                { cmd: "help [module]", description: "Prints help about given 'module'. If module ommited prints all available modules." } ]
      }
    { cmd_executor: core_executor([metadata | List.map(_.metadata, mods)]),
      ~metadata
    }
  }

}
