NAME = webshell.exe

SRC  = service.opa editor.opa config.opa login.opa webshell.opa \
       calc.opa facebook.opa search.opa dropbox.opa twitter.opa
SRCS = $(SRC:%=src/%)

all: $(NAME)

$(NAME): $(SRCS)
	opa --parser js-like $(SRCS) -o $(NAME)

run: $(NAME)
	./$(NAME)

clean:
	rm -f $(NAME)
	rm -rf _build
