all: README.html

PANDOC_OPTS_GENERAL = --from markdown --smart --highlight-style pygments \
                      --table-of-contents --toc-depth=4

%.html: %.md
	pandoc ${PANDOC_OPTS_GENERAL} -t html5 --standalone --mathjax=${MATHJAX} \
        --css main.css $^ -o $@
