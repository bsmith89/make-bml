---
title: (GNU)Make for reproducible bioinformatics pipelines
author: Byron J. Smith

---

This is the repository for a lesson on Make for bioinformatics pipelines at
Titus Brown's 2016 Workshop at Bodega Marine Labs


## Reference ##

-   <http://kbroman.org/minimal_make/>
-   <http://swcarpentry.github.io/make-novice/>


## TODO ##

-   [x] License
-   [ ] Port portions of the SWC Make lesson
-   [x] Outline lesson
-   [x] Write out learning objectives
-   [ ] Amend the contents of the lesson archive to streamline this lesson
    -   [ ] `chmod +x` the scripts
    -   [ ] Add an `--ascii` flag to plotwords.py
    -   [ ] Add `run_pipeline.sh` (?)
    -   [ ] Patch `countwords.py` for output to be tab delimited
-   [ ] Consider what concept/challenge questions to use during the lesson
    -   [ ] Do I want to add an answers page?
-   [ ] Harden Makefile graph plotting scripts
-   [ ] Consider making the first rule go all the way to the plot
    and then split that up into two rules.

## Learning Objectives ##

-   Students write a Makefile which processes raw data and outputs a finished
    HTML document.
-   Students set up and customize a project directory which facilitates
    version control, reproducibility, and their "build" process.
-   Students make incremental, single-effect commits to their project
    repository which preserve the state _and_ history of metadata, scripts, and
    documentation, but not intermediate data.

## Evangelizing Objectives ##
-   Students are inspired to make their workflows "reproducible" from the
    start, using a variety of tools, including Make.
-   Students understand when Make is _not_ the best choice for organizing a
    project (e.g. super compute-heavy workflows, building flexible tools, etc.)

## Requirements ##

-   UNIX system
-   GNU Make installed (particular version?)
-   Graphviz (?)
-   Python (3?)
-   Git
-   Internet connection for downloading resources.
-   Pandoc (?)
-   tree (?)
-   unzip (?)

## Outline ##

I.  Setup **[15 minutes]**
    A.  AWS?
    A.  Download SWC's [make-lesson.zip][make-lesson-zip]
        1.  Do I want to change this data?
    A.  Extract to some directory (which one?)
    A.  `tree`?
I.  Motivation (Zipf's law example) **[15 minutes]**
    A.  Describe an analysis workflow
    A.  Write (show?) a script which carries out the workflow
    A.  Explain the limitations/annoyances
        1.  What if we change one of our scripts?  What do we need to re-run?
        1.  The relationships between files aren't always obvious to a reader
        1.  Modular analyses
    A.  Describe what we really want (Make!)
        1.  Use a program to figure all of that out for us!
        1.  Write an executable description of our workflow.
        1.  Inspire best practices for git use, project directory structure.
I.  Makefile basics **[45 minutes]**
    A.  `Makefile` With just one target
        1.
            ```Makefile
            isles.dat: books/isles.txt
                python wordcount.py books/isles.txt isles.dat
            ```
        1.  Target/pre-requisite/recipe syntax
    A.  Running Make
        1.  `make [target]` (runs the recipe)
        1.  `make [target]` (target is up to date and is not re-made unless we
            `touch` the pre-requisites)
        1.  `make -n [target]` (dry-run)
        1.  `make` (no arguments; runs first recipe in the file)
    A.  Adding more recipes
        1.
            ```Makefile
            abyss.dat: books/abyss.txt
                python wordcount.py books/abyss.txt abyss.dat
            ```
        1.  Challenge question: Write two new rules
            a.  One for `last.dat`
            a.  One for `analysis.tar.gz` which is a tarball of all three
                `.dat` files
    A.  Convenience recipes
        1.  `clean` / `all`
        1.  `.PHONY` (otherwise a file named `clean` would mess everything up)
I.  Make features **[45 minutes]**
    A.  Don't Repeat Yourself (D.R.Y. Principle)
    A.  Automatic variables
        1.  `$@`
        1.  `$^`
        1.  Challenge question here
    A.  Pattern rules
        1.  Challenge question here
    A.  Functions
    A.  User-defined variables
    A.  `make -j`
    A.  `@` and `-` prefixes
I.  Best practices **[60 minutes]**
    A.  Dependency is important
        1.  Introduce a makefile-plotter?
    A.  Git integration (what do you version control?)
    A.  Don't hard-code stuff (Makefile is the source of all (most) truth)
    A.  Put it all together

[make-lesson-zip]: http://swcarpentry.github.io/make-novice/make-lesson.zip
