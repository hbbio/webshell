// license: AGPL
// (c) MLstate, 2011, 2012
// author: Adam Koprowski

database string /host

module Config {

   // TODO: abstract away this pattern
  server host =
    _ = CommandLine.filter(
      { init: void
      , parsers: [{ CommandLine.default_parser with
          names: ["--host"],
          param_doc: "HOST",
          description: "Sets the address of the application (needed for all redirects)",
          function on_param(state) {
            parser {
              case host=(.*) :
              {
                /host <- Text.to_string(host)
                {no_params: state}
              }
            }
          }
        }]
      , anonymous: []
      , title: "General options"
      }
    )
    match (?/host) {
      case {some: host}: host
      default:
        Log.error("webshell[config]", "Cannot read host configuration
Please re-run your application with: --host option")
        System.exit(1)
    }

}
