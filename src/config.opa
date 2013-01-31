// license: AGPL
// (c) MLstate, 2011, 2012
// author: Adam Koprowski

database string /host

module Config {

   // TODO: abstract away this pattern
  server host =
    state = CommandLine.filter(
      { init: none
      , parsers: [{ CommandLine.default_parser with
          names: ["--host"],
          param_doc: "HOST",
          description: "Sets the address of the application (needed for all redirects)",
          function on_param(state) {
            parser {
              case host=(.*) :
              {
                // /host <- Text.to_string(host)
                {no_params: some(Text.to_string(host))}
              }
            }
          }
        }]
      , anonymous: []
      , title: "General options"
      }
    )
    match (state) {
      case {some: s}: s
      default:
        Log.error("webshell[config]", "Cannot read host configuration
Please re-run your application with: --host option")
        System.exit(1)
    }

}
