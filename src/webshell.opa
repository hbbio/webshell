// license: AGPL
// (c) MLstate, 2011, 2012
// author: Henri Binsztok
// author: Adam Koprowski (adding Facebook-connectivity)

import stdlib.themes.bootstrap
import stdlib.widgets.bootstrap

WB = WBootstrap

calc = Service.make(Calc)
search = Service.make(Search)
dropbox = Service.make(DropboxConnect)
twitter = Service.make(TwitterConnect)
facebook = Service.make(FacebookConnect)

shell = Shell.build([calc.handler, search.handler, dropbox.handler, twitter.handler, facebook.handler])

function focus(set) {
  Log.warning("focus", set);
  #status = "Focus: {set}";
}

function prompt() {
  <>
    <span class="prompt">web: </span>
    <span class="username">{Login.get_current_user_name()}</>
    <span class="prompt"> $ </span>
  </>
}

function warner(msg) {
  #terminal_prev =+ msg;
}

function asker(_f, msg) {
  #terminal_prev =+ msg;
}

function loop(ua)(_) {
  LineEditor.init(ua, #editor, readevalwrite(_), true);
}

function readevalwrite(cmd) {
  element =
    <div>
      <span>{prompt()}</span>
      <span>{cmd}</span>
    </div>
    <div>{Shell.execute(shell, cmd)}</div>;
  update(element);
}

client function update(xhtml element) {
  #terminal_prev =+ element;
  LineEditor.clear();
  Dom.scroll_to_bottom(#terminal);
  Dom.scroll_to_bottom(Dom.select_window());
}

function login_box() {
  function block(content) {
    <h3 style="float: right">{content}</>
  }
  login = <>{FacebookConnect.xhtml}</>
  logout =
    function do_logout(_) {
      Login.set_current_user({guest})
      Client.reload()
    }
    name = <a>{Login.get_current_user_name()}</>
    button = WBootstrap.Button.make({ button: <>Logout</>, callback: do_logout}, [])
    block(<>{button}{name}</>)
  content =
    match (Login.get_current_user()) {
      case {guest}: login
      default: logout
    }
  <span class=userbox>{content}</>
}

function page(cmd) {
  topbar =
    WB.Navigation.fixed_navbar(
      WB.Layout.fixed(
        WB.Navigation.brand(<>webshell</>, none, ignore) <+>
        {login_box()}
      ),
      {top}
    )
  html = WB.Layout.fixed(
    <div id="terminal">
      <div id="terminal_prev" />
      <div id="terminal_curr" onready={loop(HttpRequest.get_user_agent())}>
        {prompt()}
        <span id="editor"/>
      </>
    </>
  )
  function onready(_) {
    match (cmd) {
    case {some: cmd}: readevalwrite(cmd)
    default: void
    }
  }
  Resource.html("webshell",
     <>
       {topbar}
       <span onready={onready}>{html}</>
       <div id="status"/>
     </>
   )
}

function connect(connector, raw_data) {
  _ = connector(Text.to_string(raw_data))
  Resource.default_redirection_page("/")
}

dispatcher = parser {
  case "/connect/facebook?" data=(.*) ->
    connect(FacebookConnect.login(facebook.fun_executor), data)
  case "/connect/twitter?" data=(.*) ->
    connect(TwitterConnect.login(twitter.fun_executor), data)
  case "/connect/dropbox?" data=(.*) ->
    connect(DropboxConnect.login(dropbox.fun_executor), data)
  case "/do=" cmd=(.*) ->
    page(some(Text.to_string(cmd)))
  case .* ->
    page(none)
}

Server.start(Server.http,
             [ { resources: @static_resource_directory("resources") }
             , { register: [{css: ["resources/style.css"]}] }
             , { custom: dispatcher }
             ]
            )
