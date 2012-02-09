// license: AGPL
// (c) MLstate, 2011, 2012
// author: Henri Binsztok
// author: Adam Koprowski (adding blinking cursor)
// Useful link: http://unixpapa.com/js/testkey.html

client module Capture {
	dhh = Reference.create({none});

        function user_agent_to_bind_options(option(user_compat) user_agent) {
          (list(Dom.event_option)) match (user_agent) {
            case {some:ua}:
              match (ua.renderer) {
                case {Bot:_}: [];
                case {Gecko:_}: [{stop_propagation}];
                case {Trident:_}: [];
                case {Webkit:_, variant:_}: [];
                case {Nokia:_}: [];
                case {Presto:_}: [{prevent_default}];
                case {Unidentified}: [];
              }
            case {none}: [];
          }
        }

	function set(option(user_compat) user_agent, fpress, fdown) {
		doc = Dom.select_document();
                options = user_agent_to_bind_options(user_agent);
                hpress = Dom.bind_with_options(doc, { keypress }, fpress(_), options);
                hdown = Dom.bind_with_options(doc, { keydown }, fdown(_), options);
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

	editor =
          <span id="precaret" /><span id="caret" style={css {margin: 0px 1px; color: lime}}>█</><span id="postcaret" />

        private blinking_delay = 600

        function cursor_blink() {
          effect = Dom.Effect.fade_toggle()
                |> Dom.Effect.with_duration({millisec: blinking_delay/2}, _)
          _ = Dom.transition(#caret, effect)
          void
        }

	function init(option(user_compat) user_agent, selector, callback, echo) {
		*selector = editor;
                Scheduler.timer(blinking_delay, cursor_blink)
		Capture.set(user_agent, evalKeyPress(echo, _), evalKeyDown(callback, _));
	}
	
	function get() {
		"{Dom.get_content(#precaret)}{Dom.get_content(#postcaret)}"
	}
	
	function clear() {
		#precaret="";
		#postcaret="";
	}

        function evalKeyPress(echo, event) {
          match ((event.key_modifiers,event.key_code)) {
            case (_,{none}): #status = "KeyPress not captured";
            case ([],{some: 8}): void;
            case ([],{some: 13}): void;
            case (_,{some: key}): #status = "Key: {key}"; addChar(echo, event, key);
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
			if (List.mem({shift}, event.key_modifiers)) { symbol; }
			else { String.to_lower(symbol); };
		match(key) {
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

