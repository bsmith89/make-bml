all: README.html

%.html: %.md
	pandoc -t html5 -o $@ $^
