// license: AGPL
// (c) MLstate, 2011
// author: Henri Binsztok

import stdlib.themes.bootstrap
import stdlib.widgets.bootstrap

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

client function warner(msg) {
	#terminal =+ msg;
}

client function asker(f, msg) {
	#terminal =+ msg;	
}

client function loop(_) {
	LineEditor.init(#editor, readevalwrite, true);
}
		
client function readevalwrite(expr) {
	element = 
		<div>
			<span>{prompt({none})}</span>
			<span>{expr}</span>
		</div>
		<div>{Calc.compute(expr)}</div>;
	#terminal =+ element;
	LineEditor.clear();
	Dom.scroll_to_bottom(Dom.select_window());
}

function page() {
	html = WBootstrap.Layout.fixed(
	WBootstrap.Typography.header(1, none,
		<div id="terminal"/>
		<div id="line" onready={loop}>
			{prompt({none})}
			<span id="editor"/>
		</div>
	));
	<>{html}</>
	<div id="status"/>
}

Server.start(
	Server.http, { ~page, title: "webshell" }
)
