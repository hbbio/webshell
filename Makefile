NAME = webshell.exe

SRC  = service.opa parser.opa editor.opa webshell.opa login.opa facebook.opa search.opa dropbox.opa config.opa
SRCS = $(SRC:%=src/%)

all: $(NAME)

$(NAME): $(SRCS)
	opa --parser js-like $(SRCS) -o $(NAME)

run: $(NAME)
	./$(NAME)

clean:
	rm -f $(NAME)
	rm -rf _build
