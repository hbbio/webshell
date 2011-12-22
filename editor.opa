// license: AGPL
// (c) MLstate, 2011
// author: Henri Binsztok
// Useful link: http://unixpapa.com/js/testkey.html

client module Capture {
	dhh = Reference.create({none});

	function set(fpress, fdown) {
		doc = Dom.select_document();
		hpress = Dom.bind(doc, { keypress }, fpress);
		hdown = Dom.bind(doc, { keydown }, fdown);
		Reference.set(dhh, { some: { ~doc, ~hpress, ~hdown}});
	}
	
	function unset() {
		match (Reference.get(dhh)) {
			case {none}: void;
			case {some: dhh}:
				Dom.unbind(dhh.doc, dhh.hpress);
				Dom.unbind(dhh.doc, dhh.hdown);
		}
	}
}

client module LineEditor {

	editor = <span id="precaret" style="margin-right: 0px; border-right:thick double #ff0000;"/><span id="postcaret" style="margin-left: 0px; padding-left: 0px;"/>;
	
	function init(selector, callback, echo) {
		*selector = editor;
		Capture.set(evalKeyPress(echo, _), evalKeyDown(callback, _));
	}
	
	function get() {
		"{Dom.get_content(#precaret)}{Dom.get_content(#postcaret)}"
	}
	
	function clear() {
		#precaret="";
		#postcaret="";
	}
	
	function evalKeyPress(echo, event) {
		match (event.key_code) {
			case {none}: #status = "KeyPress not captured";
			case {some: 13}: void;
			case {some: key}: #status = "Key: {key}"; addChar(echo, event, key);
		}
	}

	function evalKeyDown(callback, event) {
		match (event.key_code) {
			case {none}: #status = "KeyDown not captured";
			case {some: 8}: #status = "Backspace"; deleteChar();
			case {some: 13}:
				#status = "Enter";
				//Capture.unset();
				callback(get());
			case {some: 37}: #status = "Left"; move({left});
			case {some: 38}: #status = "Up"; move({up});
			case {some: 39}: #status = "Right"; move({right});
			case {some: 40}: #status = "down"; move({down});
			case {some: key}:  #status = "Key: {key} discarded"; void;
		}
	}
	
	function addChar(echo, event, key) {
	symbol = String.of_byte_unsafe(key);
	symbol = 
		// match (List.assoc(key, keymap)) {
		// case {none}:
			if (List.mem({shift}, event.key_modifiers)) { symbol; } // ; is compulsory...
			else { String.to_lower(symbol); };
		// case {some: symbol}:
		//	symbol;
		// }
	match(key) {
		// case missing -> syntax error reported too early
		case 16: void; // Shift
		default: if (echo) { #precaret =+ symbol; } else void;
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
	
}

