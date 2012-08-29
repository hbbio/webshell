// license: AGPL
// (c) MLstate, 2012
// author: Adam Koprowski

import stdlib.apis.dropbox
import stdlib.web.client

database Dropbox.conf /dropbox_config

 // TODO? could the generic OAuth authentication be bundled in that module?
 //       only providing a single simple function?
type Dropbox.status = {no_credentials}
                   or {string request_secret, string request_token}
                   or {Dropbox.creds authenticated, string path}

module DropboxConnect {

  private server config =
    state = CommandLine.filter(
      { init: none
      , parsers: [{ CommandLine.default_parser with
          names: ["--dropbox-config"],
          param_doc: "APP_KEY,APP_SECRET",
          description: "Sets the application data for the associated Dropbox application",
          function on_param(state) {
            parser {
              case app_key=Rule.alphanum_string [,] app_secret=Rule.alphanum_string :
              {
                db_config = ~{app_key, app_secret}
                // /dropbox_config <- db_config
                {no_params: some(db_config)}
              }
            }
          }
        }]
      , anonymous: []
      , title: "Dropbox configuration"
      }
    )
    match (state) {
      case {some: config}: config
      default:
        Log.error("webshell[config]", "Cannot read Dropbox configuration (application key and/or secret key)
Please re-run your application with: --dropbox-config option")
        System.exit(1)
    }

  private DB = Dropbox(config)

  private redirect = "http://{Config.host}/connect/dropbox"

  function login(executor)(raw_token) {
    function connect(auth_data) {
      Log.info("Dropbox", "connection data: {raw_token}")
      authentication_failed = {no_credentials}
      match (auth_data) {
      case ~{request_secret, request_token}:
        match (DB.OAuth.connection_result(raw_token)) {
        case {success: s}:
          if (s.token == request_token) {
            match (DB.OAuth.get_access_token(s.token, request_secret, s.verifier)) {
            case {success: s}:
              dropbox_creds = {token: s.token, secret: s.secret}
              Log.info("Dropbox", "got credentials: {dropbox_creds}")
              {authenticated: dropbox_creds, path: "/"}
            default:
              authentication_failed
            }
          } else
            authentication_failed
        default:
          authentication_failed
        }
      default:
        authentication_failed
      }
    }
    executor(connect)
  }

  private function authenticate() {
    token = DB.OAuth.get_request_token(redirect)
    Log.info("Dropbox", "Obtained request token {token}")
    match (token) {
    case {success: token}:
      auth_url = DB.OAuth.build_authorize_url(token.token, redirect)
      auth_state = {request_secret: token.secret, request_token: token.token}
      { response: {redirect: auth_url},
        state_change: {new_state: auth_state}
      }
    default:
      Service.respond_with(<>Dropbox authorization failed</>)
    }
  }

  private function pad(length, s) {
    String.pad_left(" ", length, s)
  }

  private date_printer = Date.generate_printer("%Y-%m-%d %k:%M")

  private function show_element(path, Dropbox.element element) {
    function get_name(fname) {
      drop_prefix = if (String.has_prefix("/", path)) path else "/{path}"
      if (String.has_prefix(drop_prefix, fname))
        String.drop_left(String.length(drop_prefix), fname)
      else
        fname
    }
    (info, fname, size) =
      match (element) {
      case {file, ~metadata, ...}:
        Log.info("DB", "path: {path}, filename: {metadata.path}");
        name = get_name(metadata.path)
        (metadata, <>{name}</>, "{metadata.size}")
      case {folder, ~metadata, ...}:
        name = <span class="fn-type-folder">{get_name(metadata.path)}</>
        (metadata, name, "")
      }
    final_size = size |> pad(10, _)
    show_date = Date.to_formatted_string(date_printer, _)
    modification = Option.map(show_date, info.modified) ? ""
    <pre>{final_size}   {modification}   {fname}</>
  }

  private function files_to_xhtml(files, path) {
    <>{List.map(show_element(path, _), files)}</>
  }

  function sanitize_url(url) {
    String.replace(" ", "%20", url) // shouldn't this be taken care of somewhere in stdlib?
  }

  function normalize_path(path) {
    recursive function aux(segs) {
      match (segs) {
      case []: []
      case ["." | xs]: aux(xs)
      case [_x, ".." | xs]: aux(xs)
      case [x | xs]: [x | aux(xs)]
      }
    }
    String.explode_with("/", path, true)
      |> aux
      |> List.to_string_using("", "/", "/", _)
  }

  function path_available(path) {
    true // FIXME
  }

  function ls(state) {
    match (state) {
    case {authenticated: creds, ~path}:
      db_files = DB.Files("dropbox", sanitize_url(path)).metadata(DB.default_metadata_options, creds)
      response =
        match (db_files) {
        case {success: {~contents, ...}}: files_to_xhtml(contents ? [], path)
        default: <>Dropbox connection failed</>
        }
      Service.respond_with(response)
    default:
      authenticate()
    }
  }

  function cd(state, cd_path) {
    match (state) {
    case {authenticated: creds, ~path}:
      new_path = normalize_path("{path}/{cd_path}")
      if (path_available(new_path))
        { response: {outcome: <></>},
          state_change: {new_state: {authenticated: creds, path: new_path}}
        }
      else
        Service.respond_with(<>cd: {cd_path}: No such file or directory</>)
    default:
      authenticate()
    }
  }

  Service.spec spec =
    { initial_state: Dropbox.status {no_credentials},
      metadata: {
        id: "dropbox",
        description: "Managing Dropbox file storage",
        cmds: [
          { cmd: "ls", description: "Lists contents of the current directory" },
          { cmd: "cd [path]", description: "Change to given directory" }
        ],
      },
      function parse_cmd(state) {
        parser {
        case "ls": ls(state)
        case "cd" Rule.ws path=(.*) : cd(state, Text.to_string(path))
        }
      }
    }

}
