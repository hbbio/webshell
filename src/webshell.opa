// license: AGPL
// (c) MLstate, 2011, 2012
// author: Henri Binsztok
// author: Adam Koprowski (adding Facebook-connectivity)

import stdlib.themes.bootstrap
import stdlib.widgets.bootstrap

WB = WBootstrap

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

function answer(expr) {
  (xhtml) match (Parser.try_parse(Calc.shell, expr)) {
    case { none }: <>syntax error</>
    case { some: { value: result } }: <>{result}</>
    case { some: { ~command, ~arg } }: <>{command}({arg})</>
    case { some: { search:args } }: Search.search(args)
    case { some: { set:args } }: Search.set(args)
    case { some: { next } }: Search.next()
    case { some: { prev } }: Search.prev()
    case { some: { ~pagenum } }: Search.page(pagenum)
  }
}

function readevalwrite(expr) {
  element =
    <div>
      <span>{prompt()}</span>
      <span>{expr}</span>
    </div>
    <div>{answer(expr)}</div>;
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
  login =
    prompt = <a>You can sign in with:</>
    block(<>{prompt}{FacebookConnect.xhtml}{DropboxConnect.xhtml}</>)
  logout =
    function do_logout(_) {
      Login.set_current_user({guest})
      Client.reload()
    }
    name = <a>{Login.get_current_user_name()}</>
    button = WBootstrap.Button.make({ button: <>Logout</>, callback: do_logout}, [])
    block(<>{button}{name}</>)
  match (Login.get_current_user()) {
    case {guest}: login
    default: logout
  }
}

function page() {
  topbar =
    WB.Navigation.topbar(
      WB.Layout.fixed(
        WB.Navigation.brand(<>webshell</>, none, ignore) <+>
        {login_box()}
      )
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
  Resource.html("webshell",
     <>
       {topbar}
       {html}
       <div id="status"/>
     </>
   )
}

function connect(connector, raw_data) {
  connector(Text.to_string(raw_data))
  Resource.default_redirection_page("/")
}

dispatcher = parser
| "/connect/facebook?" data=(.*) -> connect(FacebookConnect.login, data)
| "/connect/dropbox?" data=(.*) -> connect(DropboxConnect.connect, data)
| .* -> page()

Server.start(Server.http, { custom: dispatcher })

css = css
  #Body {
    background-color: #444;
  }
  #terminal {
    border: 1px solid gray;
    padding: 4px;
    margin-top: 80px;
    overflow-y: scroll;
    width: 100%;
    height: 500px;
    font-family: courier, monospace;
    color: white;
    font-size: 14px;
    background-color: black;
  }
  .search-index {
    color: yellow;
  }
  .search-title {
    color: red;
  }
  .search-pubDate {
    color: dimgrey;
  }
  .username {
    color: lime;
  }
  .prompt {
    color: #0BC;
  }
