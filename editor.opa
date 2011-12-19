// license: AGPL
// (c) MLstate, 2011
// author: Henri Binsztok

// keymap = []

function addChar(event, key) {
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

client function warner(msg) {
	#inputs =+ msg;
}

client function asker(f, msg) {
	#inputs =+ msg;	
}
