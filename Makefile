NAME = webshell.exe

SRC  = parser.opa user.opa editor.opa webshell.opa

all: $(NAME)

$(NAME): $(SRC)
	opa --parser js-like $(SRC)

clean:
	rm -f $(NAME)
	rm -rf _build
