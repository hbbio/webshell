// license: AGPL
// (c) MLstate, 2011
// author: Henri Binsztok

import stdlib.crypto

type user = { string password, list(string) history }

database stringmap(user) /users ;	  

module User {

	function create(warner, asker, username) {
		match (?/users[username]/password) {
			case {none}:
				password = asker(Crypto.Hash.sha2, "password:");
				user = {~password, history: []};
				/users[username] <- user;
			default: warner("user {username} exists");
		}
	}
	
	function login(warner, asker, username) {
		match (?/users[username]/password) {
			case {none}: 
				warner("user {username} unknown"); 
				false;
			case {some: p1}:
				p2 = asker(Crypto.Hash.sha2, "password:");
				if (p1 == p2) { true; }
				else { warner("invalid password"); false; }
		}
	}
	
}
