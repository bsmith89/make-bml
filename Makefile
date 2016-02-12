LESSON=lesson
SITE_DIR=.site
CLEANUP = README.html ${LESSON}.html ${SITE_DIR}

all: ${LESSON}.html

PANDOC_OPTS_GENERAL = --from markdown --smart --highlight-style pygments \
                      --table-of-contents --toc-depth=4 --preserve-tabs

%.html: %.md
	pandoc ${PANDOC_OPTS_GENERAL} -t html5 --standalone \
        --css main.css $^ -o $@


clean:
	rm -rf ${CLEANUP}

${SITE_DIR}: ${LESSON}.html main.css
	rm -rf $@
	mkdir $@
	cp $^ $@
	cp $< $@/index.html

gh-pages: ${SITE_DIR}
	ghp-import -b gh-pages -m "`date`" -p ${SITE_DIR}
