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

function prompt(login) {
	<span class="prompt">
	{ match (login) {
		case {none}: "web: anonymous $ ";
		case {some: username}: "web: {username} $ "; } }
	</span>
}

function warner(msg) {
	#terminal =+ msg;
}

function asker(f, msg) {
	#terminal =+ msg;	
}

function loop(_) {
	LineEditor.init(#editor, readevalwrite, true);
}
		

function answer(expr) {
	match (Parser.try_parse(Calc.shell, expr)) {
		case { none }: "syntax error"
		case { some: { value: result } }: "{result}"
		case { some: { ~command, ~arg } }: "{command}({arg})"
	}
}
		
client function readevalwrite(expr) {
	element = 
		<div>
			<span>{prompt({none})}</span>
			<span>{expr}</span>
		</div>
		<div>{answer(expr)}</div>;
	#terminal =+ element;
	LineEditor.clear();
	Dom.scroll_to_bottom(Dom.select_window());
}

function page() {
  topbar =
    WB.Navigation.topbar(
      WB.Layout.fixed(
        WB.Navigation.brand(<>webshell</>, none, ignore)
      )
    )
  html = WB.Layout.fixed(
    WB.Typography.header(1, none,
      <div id="terminal"/>
        <div id="line" onready={loop}>
          {prompt({none})}
          <span id="editor"/>
        </div>
     )
   ) |> Xhtml.update_class("body", _)
   <>
     {topbar}
     {html}
     <div id="status"/>
   </>
}

Server.start(
	Server.http, { ~page, title: "webshell" }
)

css = css
  .body { padding-top: 50px }
