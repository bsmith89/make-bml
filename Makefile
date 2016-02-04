all: make-lesson.html

PANDOC_OPTS_GENERAL = --from markdown --smart --highlight-style pygments \
                      --table-of-contents --toc-depth=4 --preserve-tabs

%.html: %.md
	pandoc ${PANDOC_OPTS_GENERAL} -t html5 --standalone --mathjax=${MATHJAX} \
        --css main.css $^ -o $@


CLEANUP = README.html

clean:
	rm -f ${CLEANUP}
