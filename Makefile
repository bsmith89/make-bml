LESSON=make-lesson

all: ${LESSON}.html

PANDOC_OPTS_GENERAL = --from markdown --smart --highlight-style pygments \
                      --table-of-contents --toc-depth=4 --preserve-tabs

%.html: %.md
	pandoc ${PANDOC_OPTS_GENERAL} -t html5 --standalone \
        --css main.css $^ -o $@


CLEANUP = README.html make-lesson.html

clean:
	rm -f ${CLEANUP} docs

docs/index.md: ${LESSON}.md
	mkdir -p ${@D}
	cp $^ $@

gh-pages: docs/index.md
	mkdocs gh-deploy --clean
