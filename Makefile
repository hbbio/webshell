NAME = webshell.exe

SRC  = calc.opa webshell.opa

all: $(NAME)

$(NAME):
	opa --parser js-like $(SRC)

clean:
	rm -f $(NAME)
	rm -rf _build
