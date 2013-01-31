// license: AGPL
// (c) MLstate, 2011, 2012
// author: Adam Koprowski

import stdlib.apis.{facebook, facebook.auth, facebook.graph}
import stdlib.{web.client, system}

 // FIXME should be abstract...
type FacebookConnect.user =
  { FbAuth.token token
  , string name
  }

database Facebook.config /facebook_config

type Facebook.status = {no_credentials}
                    or {FbAuth.token authenticated}

module FacebookConnect
{

  server config =
    state = CommandLine.filter(
      { init: none
      , parsers: [{ CommandLine.default_parser with
          names: ["--fb-config"],
          param_doc: "APP_ID,APP_SECRET",
          description: "Sets the application ID for the associated Facebook application",
          function on_param(state) {
            parser {
              case app_id=Rule.alphanum_string [,] app_secret=Rule.alphanum_string:
              {
                fb_config = {~app_id, api_key: app_id, ~app_secret};
                // /facebook_config <- fb_config
                {no_params: some(fb_config)}
              }
            }
          }
        }]
      , anonymous: []
      , title: "Facebook configuration"
      }
    )
    match (state) {
      case {some: config}: config
      default:
        Log.error("webshell[config]", "Cannot read Facebook configuration (application id and/or secret key)
Please re-run your application with: --fb-config option")
        System.exit(1)
    }

  private FBA = FbAuth(config)
  private FBG = FbGraph

  private redirect = "http://{Config.host}/connect/facebook"

  private function get_fb_name(token) {
    opts = { FBG.Read.default_object with token:token.token }
    default_name = "<unknown name>"
    match (FBG.Read.object("me", opts)) {
      case {~object}:
        match (List.assoc("name", object.data)) {
          case {some: {String: v}}: v
          default: default_name
        }
      default: default_name
    }
  }

  private auth_url = FBA.user_login_url([{publish_stream}], redirect)

  xhtml =
    <a onclick={function (_) { Client.goto(auth_url) }}>
      <img src="resources/img/facebook_signin.png" />
    </>

  function login(executor)(token) {
    function connect(_) {
      match (FBA.get_token_raw(token, redirect)) {
      case {~token}:
        fb_user = { ~token, name: get_fb_name(token) }
        Login.set_current_user({~fb_user});
        {authenticated: token}
      case {error:_}: {no_credentials}
      }
    }
    executor(connect)
  }

  function get_name(user) {
    user.name
  }

  private function authenticate() {
    { response: {redirect: auth_url},
      state_change: {no_change}
    }
  }


  function publish_status(state, status) {
    match (state) {
    case {authenticated: creds}:
      feed = { Facebook.empty_feed with message: status }
      outcome = FbGraph.Post.feed(feed, creds.token)
      response =
        match (outcome) {
        case {success:_}: <>Successfully published Facebook feed item: «{feed.message}»</>
        case {~error}: <>Error: <b>{error.error}</b>; {error.error_description}</>
        }
      Service.respond_with(response)
    default:
      authenticate()
    }
  }

  Service.spec spec =
    { initial_state: Facebook.status {no_credentials},
      metadata: {
        id: "facebook",
        description: "Managing Facebook account",
        cmds: [
          { cmd: "fbstatus [content]", description: "Publishes a given Facebook status" }
        ],
      },
      function parse_cmd(state) {
        parser {
        case "fbstatus" Rule.ws content=(.*) : publish_status(state, Text.to_string(content))
        }
      }
    }

}
