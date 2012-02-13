// license: AGPL
// (c) MLstate, 2011, 2012
// author: Adam Koprowski

abstract type Login.user = {guest} or {FacebookConnect.user fb_user}

module Login {

  user = UserContext.make({guest})

  function Login.user get_current_user() {
    UserContext.execute(identity, user)
  }

  function set_current_user(Login.user new_user) {
    UserContext.change_or_destroy(function (_) { some(new_user) }, user)
  }

  function get_current_user_name() {
    match (get_current_user()) {
      case {guest}: "anonymous"
      case {~fb_user}: FacebookConnect.get_name(fb_user)
    }
  }

}
