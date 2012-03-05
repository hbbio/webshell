// license: AGPL
// (c) MLstate, 2012
// author: Adam Koprowski

import stdlib.apis.dropbox
import stdlib.web.client

database Dropbox.conf /dropbox_config

 // TODO? could the generic OAuth authentication be bundled in that module?
 //       only providing a single simple function?
type Dropbox.credentials = {no_credentials}
                        or {string request_secret, string request_token}
                        or {Dropbox.creds authenticated}

module DropboxConnect {

  private server config =
    _ = CommandLine.filter(
      { init: void
      , parsers: [{ CommandLine.default_parser with
          names: ["--dropbox-config"],
          param_doc: "APP_KEY,APP_SECRET",
          description: "Sets the application data for the associated Dropbox application",
          function on_param(state) {
            parser {
              case app_key=Rule.alphanum_string [,] app_secret=Rule.alphanum_string :
              {
                /dropbox_config <- ~{app_key, app_secret}
                {no_params: state}
              }
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

  private DB = Dropbox(config)

  private redirect = "http://{Config.host}/connect/dropbox"

  private creds = UserContext.make(Dropbox.credentials {no_credentials})

  private function set_auth_data(data) {
    UserContext.change(function(_) { data }, creds)
  }

  private function get_auth_data() {
    UserContext.execute(identity, creds)
  }

  private function authentication_failed() {
    Log.info("Dropbox", "authentication failed")
  }

  function connect(data) {
    Log.info("Dropbox", "connection data: {data}")
    match (get_auth_data()) {
      case ~{request_secret, request_token}:
        match (DB.OAuth.connection_result(data)) {
          case {success: s}:
            if (s.token == request_token) {
              match (DB.OAuth.get_access_token(s.token, request_secret, s.verifier)) {
                case {success: s}:
                  dropbox_creds = {token: s.token, secret: s.secret}
                  Log.info("Dropbox", "got credentials: {dropbox_creds}")
                  {authenticated: dropbox_creds} |> set_auth_data
                default:
                  authentication_failed()
              }
            } else
              authentication_failed()
           default:
              authentication_failed()
        }
      default:
        authentication_failed()
    }
  }

  function authenticate() {
    token = DB.OAuth.get_request_token(redirect)
    Log.info("Dropbox", "Obtained request token {token}")
    match (token) {
      case {success: token}:
          auth_url = DB.OAuth.build_authorize_url(token.token, redirect)
          {request_secret: token.secret, request_token: token.token} |> set_auth_data
          Client.goto(auth_url)
          none
        default:
          Log.error("Dropbox", "authorization failed")
          none
      }
  }

  exposed function get_creds() {
    match (get_auth_data()) {
      case {authenticated: data}: some(data)
      default:
        authenticate();
        none
    }
  }

  xhtml =
    WBootstrap.Button.make(
      { button:
         <span>Dropbox</>
      , callback: function(_) { ls() }
      },
      []
    )

  function ls() {
    match (get_creds()) {
      case {some: creds}:
        files = DB.Files("dropbox", "/").metadata(DB.default_metadata_options, creds)
        Log.info("Dropbox", "Files: {files}")
      default:
        authentication_failed()
    }
  }

}
