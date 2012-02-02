// license: AGPL
// (c) MLstate, 2011, 2012
// author: Adam Koprowski

import stdlib.apis.{facebook, facebook.auth, facebook.graph}
import stdlib.{web.client, system}

 // FIXME should be abstract...
type FbLogin.user =
  { FbAuth.token token
  , string name
  }

database Facebook.config /facebook_config

module FbLogin
{

  server config =
    _ = CommandLine.filter(
      { init: void
      , parsers: [{ CommandLine.default_parser with
          names: ["--fb-config"],
          param_doc: "APP_ID,APP_SECRET",
          description: "Sets the application ID for the associated Facebook application",
          function on_param(state) {
            parser app_id=Rule.alphanum_string [,] app_secret=Rule.alphanum_string ->
            {
              /facebook_config <- {~app_id, api_key: app_id, ~app_secret};
              {no_params: state}
            }
          }
        }]
      , anonymous: []
      , title: "Webshell: Facebook configuration"
      }
    )
    match (?/facebook_config) {
      case {some: config}: config
      default:
        Log.error("webshell[config]", "Cannot read Facebook configuration (application id and/or secret key)
Please re-run your application with: --fb-config APP_ID,APP_SECRET")
        System.exit(1)
    }

  private FBA = FbAuth(config)
  private FBG = FbGraph

  private redirect = "http://webshell.tutorials.opalang.org/connect"

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

  xhtml =
    login_url = FBA.user_login_url([], redirect)
    WBootstrap.Button.make(
      { button:
         <img style="width:18px; height:18px; vertical-align:top;" title="Facebook" src="https://opalang.org/sso/img/fb-icon.png" alt="Connect with Facebook" />
         <span>Facebook</>
      , callback: function(_) { Client.goto(login_url) }
      },
      []
    )

  function User.t login(token) {
    match (FBA.get_token_raw(token, redirect)) {
      case {~token}:
        fb_user = { ~token, name: get_fb_name(token) }
        {~fb_user}
      case {error:_}: {guest}
    }
  }

  function get_name(user) {
    user.name
  }

}
