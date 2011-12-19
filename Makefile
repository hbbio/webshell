NAME = webshell.exe

SRC  = calc.opa user.opa webshell.opa

all: $(NAME)

$(NAME):
	opa --parser js-like $(SRC)

clean:
	rm -f $(NAME)
	rm -rf _build
