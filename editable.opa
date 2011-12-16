// license: AGPL
// (c) MLstate, 2011
// author: Henri Binsztok

import stdlib.themes.bootstrap
import stdlib.widgets.bootstrap

keymap = [ (53, "("),(187, "+" ), (188, ","), (189, "-"), 
	       (190, "."), (191, "/" ), (221, "*") ] // change: will be {}

function addChar(event, key) {
	symbol = Text.to_string(Text.from_character(key));
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
	}
}

function eval(event) {
	// jlog("{event.key_code}");
	match (event.key_code) {
		case {none}: #status = "Key not captured";
		case {some: 8}: #status = "Backspace"; deleteChar();
		case {some: 13}: #status = "Enter"; addLine(Calc.compute);
		case {some: 37}: #status = "Left"; move({left});
		case {some: 39}: #status = "Right"; move({right});
		case {some: key}: #status = "Key: {key}"; addChar(event, key);
	}
}

function focus(set) {
	Log.warning("focus", set);
	#status = "Focus: {set}";
}

newLine =
	WBootstrap.Typography.header(1, none,
		<span id="precaret" style="margin-right: 0px; border-right:thick double #ff0000;"></span>
		<span id="postcaret" style="margin-left: 0px; padding-left: 0px;"></span>
	)

function addLine(f) {
	expr = "{Dom.get_content(#precaret)}{Dom.get_content(#postcaret)}";
	element = WBootstrap.Message.make(
		{alert: {title: f(expr), description: <>{expr}</>}, closable: true}, {info}
	);
	#inputs =+ element;
	#editor = newLine;
	
}

function loader(_) {
	#editor = newLine;
	window = Dom.select_window();
	handler = Dom.bind(Dom.select_document(), { keydown }, eval);
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
	Server.http, { ~page, title: "EditableArea" }
)