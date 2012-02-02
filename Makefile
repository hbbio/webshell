NAME = webshell.exe

SRC  = parser.opa editor.opa webshell.opa login.opa fb_login.opa search.opa
SRCS = $(SRC:%=src/%)

all: $(NAME)

$(NAME): $(SRCS)
	opa --parser js-like $(SRCS) -o $(NAME)

run: $(NAME)
	./$(NAME)

clean:
	rm -f $(NAME)
	rm -rf _build
