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
	#inputs =+ msg;
}

client function asker(f, msg) {
	#inputs =+ msg;	
}

function loop(_) {
	LineEditor.init(#editor, readevalwrite, true);
}
		
function readevalwrite(expr) {
	element = 
		<div>
			<span>{prompt({none})}</span>
			<span>{expr}</span>
		</div>
		<div>{Parser.compute(expr)}</div>;
	#inputs =+ element;
	LineEditor.init(#editor, readevalwrite, true);
	Dom.scroll_to_bottom(Dom.select_window());
}

// warning: no check for onload instead of onready
// warning: no check for events bound directly in the (server-side) page function
function page() {
	WBootstrap.Layout.fixed(
	WBootstrap.Typography.header(1, none,
		<div id="terminal"/>
		<div id="line" onready={loop}>
			{prompt({none})}
			<span id="editor"/>
		</div>
		<div id="status"/>
	));
}

Server.start(
	Server.http, { ~page, title: "webshell" }
)
