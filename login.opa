// license: AGPL
// (c) MLstate, 2011, 2012
// author: Adam Koprowski

module Login {

  user = UserContext.make({guest})

  function get_current_user() {
    UserContext.execute(identity, user)
  }

  function set_current_user(new_user) {
    UserContext.change_or_destroy(function (_) { some(new_user) }, user)
  }

}
