Webshell
--------

Webshell is, well, a web shell :). It allows command line access to a number of services including (you can read more about them below):

* [Blekko](http://blekko.com) - to search
* [Dropbox](http://dropbox.com) - to manage cloud storage
* [Facebook](http://facebook.com) - for social interactions
* Simple Calculator - for simple calculations
* [Twitter](http://twitter.com) - for microblogging

Webshell is still in early alpha; more functionality coming soon.

You can see it running [here](http://webshell.tutorials.opalang.org). Try `help` to see the rules of the game. Or read more about services and commands they support below.

Blekko
------

Search using Blekko search engine. Supported commands:

* `search <TERMS>` performs a given search
* `next` and `prev` shows next and previous page with results
* `page <N>` shows N'th page with results

Dropbox
-------

For now just allows to see the content of your Dropbox account. Supported commands:

* `cd <DIR>` to change directory
* `ls` to list contents of the current directory

Facebook
--------

For now allows feed updaes with `fbstatus` command. Try:

    fbstatus This status was set using webshell; how cool is that?

Simple calculator
-----------------

Accepts expressions using parenthesses `()`, addition `+`, subtraction `-`, multiplication `*` and division `/`. Try:

    3 + (4+7)/2

Twitter
-------

For now allows posting updates with `tweet` command. Try:

    tweet This tweet comes from webshell; how cool is that?
