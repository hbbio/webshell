// license: AGPL
// (c) MLstate, 2011
// author: Henri Binsztok

import stdlib.themes.bootstrap
import stdlib.widgets.bootstrap

function focus(set) {
	Log.warning("focus", set);
	#status = "Focus: {set}";
}

shell = "web: login $ ";

newLine =
	WBootstrap.Typography.header(1, none,
		<span>{shell}</span>
		<span id="precaret" style="margin-right: 0px; border-right:thick double #ff0000;"></span>
		<span id="postcaret" style="margin-left: 0px; padding-left: 0px;"></span>
	)

function addLine(f) {
	expr = "{Dom.get_content(#precaret)}{Dom.get_content(#postcaret)}";
	// element = WBootstrap.Message.make(
	// 	{alert: {title: f(expr), description: <>{expr}</>}, closable: true}, {info}
	// );
	element = WBootstrap.Typography.header(1, none,
		<div>
			<span>{shell}</span>
			<span>{expr}</span>
		</div>
		<div>{f(expr)}</div>
	);
	#inputs =+ element;
	#editor = newLine;
	Dom.scroll_to_bottom(Dom.select_window());
}

function loader(_) {
	#editor = newLine;
	// window = Dom.select_window();
	// Source: http://unixpapa.com/js/testkey.html
	_handler1 = Dom.bind(Dom.select_document(), { keypress }, eval1);
	_handler2 = Dom.bind(Dom.select_document(), { keydown }, eval2);
	void // compulsory
}

// warning: no check for onload instead of onready
// warning: no check for events bound directly in the (server-side) page function
function page() {
	WBootstrap.Layout.fixed(
	<div id="inputs"/>
	<div id="editor"
		onfocus={function(_) {focus(true);}}
		onblur={function(_) {focus(false);}}
		onready={loader}>
	</div>
	<div id="status"/>
	)
}

Server.start(
	Server.http, { ~page, title: "webshell" }
)
