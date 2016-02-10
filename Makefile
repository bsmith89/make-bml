LESSON=lesson

all: ${LESSON}.html

PANDOC_OPTS_GENERAL = --from markdown --smart --highlight-style pygments \
                      --table-of-contents --toc-depth=4 --preserve-tabs

%.html: %.md
	pandoc ${PANDOC_OPTS_GENERAL} -t html5 --standalone \
        --css main.css $^ -o $@


CLEANUP = README.html make-lesson.html

clean:
	rm -rf ${CLEANUP} docs

SITE_DIR=site/

${SITE_DIR}: ${LESSON}.html main.css
	rm -rf $@
	mkdir $@
	cp $^ $@
	cp $^ $@/index.html

gh-pages: ${SITE_DIR}
	ghp-import -b gh-pages -m "`date`" -p ${SITE_DIR}
