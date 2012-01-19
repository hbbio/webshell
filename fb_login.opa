// license: AGPL
// (c) MLstate, 2011, 2012
// author: Adam Koprowski

import stdlib.apis.{facebook, facebook.auth, facebook.graph}
import stdlib.web.client

 // FIXME should be abstract...
type FbLogin.user =
  { FbAuth.token token
  , string name
  }

module FbLogin
{

  private FBA = FbAuth(config)
  private FBG = FbGraph

  private config = WebShellFbConfig.config
  private redirect = "http://localhost:8080/connect"

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
      case {~error}: {guest}
    }
  }

  function get_name(user) {
    user.name
  }

}
