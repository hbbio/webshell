// license: AGPL
// (c) MLstate, 2011
// author: Henri Binsztok

import stdlib.themes.bootstrap
import stdlib.widgets.bootstrap

type user = { string name, string password, list(string) history }

database intmap(user) /users ;	  

// keymap = [ (53, "("),(187, "+" ), (188, ","), (189, "-"), (190, "."), (191, "/" ), (221, "*") ] // change: will be {}
keymap = []

function addChar(event, key) {
	symbol = String.of_byte_unsafe(key);
	symbol = 
		match (List.assoc(key, keymap)) {
		case {none}:
			if (List.mem({shift}, event.key_modifiers)) { symbol; } // ; is compulsory...
			else { String.to_lower(symbol); };
		case {some: symbol}:
			symbol;
		}
	match(key) {
		// case Dom.Key.LEFT: void;
		// case missing -> syntax error reported too early
		case 16: void; // Shift
		default: #precaret =+ symbol;
	}
}

function deleteChar() {
	previous = Dom.get_content(#precaret);
	#precaret = String.sub(0, String.length(previous) - 1, previous);
}

function move(dir) {
	match (dir) {
		case {left}:
			previous = Dom.get_content(#precaret);
			#precaret = String.sub(0, String.length(previous) - 1, previous);
			#postcaret += String.get(String.length(previous) - 1, previous);
		case {right}:
			previous = Dom.get_content(#postcaret);
			#postcaret = String.sub(1, String.length(previous) - 1, previous);
			#precaret =+ String.get(0, previous);
		case {rightmost}:
			#precaret =+ Dom.get_content(#postcaret);
			#postcaret = <></>;
		case {up}: void;
		case {down}: void;
	}
}

function eval1(event) {
	match (event.key_code) {
		case {none}: #status = "Key not captured";
		case {some: key}: #status = "Key: {key}"; addChar(event, key);
	}
}

function eval2(event) {
	match (event.key_code) {
		case {none}: #status = "Key not captured";
		case {some: 8}: #status = "Backspace"; deleteChar();
		case {some: 13}: #status = "Enter"; addLine(Calc.compute);
		case {some: 37}: #status = "Left"; move({left});
		case {some: 38}: #status = "Up"; move({up});
		case {some: 39}: #status = "Right"; move({right});
		case {some: 40}: #status = "down"; move({down});
		case {some: key}:  #status = "Key: {key} discarded"; void;
	}
}

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
