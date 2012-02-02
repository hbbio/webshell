// license: AGPL
// (c) MLstate, 2012
// author: Adam Koprowski

import stdlib.apis.dropbox
import stdlib.web.client

database Dropbox.conf /dropbox_config

module DropboxConnect {

  private server config =
    _ = CommandLine.filter(
      { init: void
      , parsers: [{ CommandLine.default_parser with
          names: ["--dropbox-config"],
          param_doc: "APP_KEY,APP_SECRET",
          description: "Sets the application data for the associated Dropbox application",
          function on_param(state) {
            parser app_key=Rule.alphanum_string [,] app_secret=Rule.alphanum_string ->
            {
              /dropbox_config <- ~{app_key, app_secret}
              {no_params: state}
            }
          }
        }]
      , anonymous: []
      , title: "Dropbox configuration"
      }
    )
    match (?/dropbox_config) {
      case {some: config}: config
      default:
        Log.error("webshell[config]", "Cannot read Dropbox configuration (application key and/or secret key)
Please re-run your application with: --dropbox-config option")
        System.exit(1)
    }

  private DropboxOAuth = Dropbox(config).OAuth

  private redirect = "http://{Config.host}/connect/dropbox"

  private access_token = UserContext.make((option(string)) none)

  exposed function get_access_token() {
    function get_token(cache) {
      match (cache) {
        case {some: token}: some(token)
        default:
          token = DropboxOAuth.get_request_token(redirect)
          match (token) {
            case {success: token}:
              auth_url = DropboxOAuth.build_authorize_url(token.token, redirect)
              Client.goto(auth_url)
              none
            default:
              Log.error("Dropbox", "authorization failed")
              none
          }
      }
    }
    UserContext.execute(get_token, access_token)
  }

  xhtml =
    WBootstrap.Button.make(
      { button:
         <span>Dropbox</>
      , callback: function(_) { token = get_access_token(); void }
      },
      []
    )

  function connect(token) {
    Log.info("Dropbox", "Registering access token {token}")
    UserContext.change(function (_) { some(token) }, access_token)
  }

}
