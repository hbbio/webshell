NAME = webshell.exe

SRC  = parser.opa editor.opa webshell.opa login.opa fb_login.opa fb_config.opa

all: $(NAME)

$(NAME): $(SRC)
	opa --parser js-like $(SRC) -o $(NAME)

clean:
	rm -f $(NAME)
	rm -rf _build
