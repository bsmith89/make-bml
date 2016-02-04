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



## Draft ##

### Setup ###

[AWS?]

For this lesson we will be using an already prepared set of files.

```bash
curl -O http://swcarpentry.github.io/make-novice/make-lesson.zip
unzip make-lesson.zip
cd make-lesson
```

[Change these files?]

Let's take a look at the files we will be working with:

```bash
tree
```

The `tree` command produces a handy tree-diagram of the directory.

```
.
├── books
│   ├── LICENSE_TEXTS.md
│   ├── abyss.txt
│   ├── isles.txt
│   ├── last.txt
│   └── sierra.txt
├── plotcount.py
└── wordcount.py

1 directory, 7 files
```

[Do we have other requirements to install?]


### Motivation ###

> The most frequently-occurring word occurs approximately twice as
> often as the second most frequent word. This is
> [Zipf's Law](http://en.wikipedia.org/wiki/Zipf%27s_law).

Let's imagine that instead of computational biology we're interested in
testing Zipf's law in some of our favorite books.
We've compiled our raw data, the books we want to analyze
(check out `head books/isles.txt`)
and have prepared several Python scripts which together make up our
analysis pipeline.

The first step is to count the frequency of each word in the book.

```bash
./wordcount.py books/isles.txt isles.words.tsv
```

Let's take a quick peek at the result.

```bash
head -5 isles.words.tsv
```

Which shows us the top 5 lines in the output file:

```
the	3822	6.7371760973
of	2460	4.33632998414
and	1723	3.03719372466
to	1479	2.60708619778
a	1308	2.30565838181
```

Each row shows the word itself, the number of occurrences of that
word, and the number of occurrences as a percentage of the total
number of words in the text file.

We can do the same thing for a different book:

```bash
./wordcount.py books/abyss.txt abyss.words.tsv
head -5 abyss.words.tsv
```

Finally, let's visualize the results.

```bash
./plotcount.py --ascii isles.words.tsv
```

The `--ascii` flag has been added so that we get a text-based
bar-plot printed to the screen.

The script is also able to plot a graphical bar-plot using matplotlib.

```bash
./plotcount.py isles.words.tsv isles.words.png
```

Together these scripts implement a common workflow:

1.  Read a data file.
2.  Perform an analysis on this data file.
3.  Write the analysis results to a new file.
4.  Plot a graph of the analysis results.
5.  Save the graph as an image, so we can put it in a paper.

#### Writing a "master" script ####

Carrying out this pipeline which transforms one book into a figure
using the command-line is pretty easy.
But what if we have multiple books?
What if the pipeline is more complicated,
What if an intermediate step takes a few minutes?

The most common solution to the tedium of data processing is to write
a master script which carries out the pipeline from start to finish.

We can make a new file, `run_pipeline.sh` which contains:

```bash
#!/usr/bin/env bash
# USAGE: bash run_pipeline.sh
# to produce plots for isles and abyss.

./wordcount.py isles.txt isles.words.tsv
./wordcount.py abyss.txt abyss.words.tsv
./plotcount.py isles.words.tsv isles.words.png
./plotcount.py abyss.words.tsv abyss.words.png

# Now archive the results in a tarball so we can share them with a colleague.
tar -czf zipf_results.tgz isles.words.tsv abyss.words.tsv \
    isles.words.png abyss.words.png
```

This master script solved several problems in computational reproducibility:

1.  It explicitly documents our pipeline,
    making communication with colleagues (and our future selves) more efficient.
2.  It allows us to type a single command, `bash run_pipeline.sh`, to
    reproduce the full analysis.
3.  It prevents us from _repeating_ typos or mistakes.
    Figure out the correct command one time only.

To continue with the good ideas, let's put everything under version control.

```bash
git init
git add wordcount.py plotcount.py
git commit -m "Write scripts to test Zipf's law."
git add run_pipeline.sh
git commit -m "Write a master script to run the pipeline."
```

A master script is a good start, but it has a few shortcomings.

Let's imagine that we adjusted the legend position
produced by `plotcount.py`.

```bash
nano plotcount.py  # Edit the plotting script
git add plotcount.py
git commit -m "Fix the figure legend."
```

Now we want to re-create our figures.
We _could_ just `bash run_pipeline.sh` again.
That would work, but it could also be a big pain if counting words takes
more than a few seconds.

Alternatively, we could manually re-run the plotting for each word-count file
and re-create the tarball.

```bash
for file in *.words.tsv; do
    ./plotcount.py $file ${file/.tsv/.png}
done

tar -czf zipf_results.tgz isles.words.tsv abyss.words.tsv \
    isles.words.png abyss.words.png
```

But then we don't get many of the benefits of having a master script.

Another popular option is to comment out the lines we don't want to
re-run.

```bash
nano run_pipeline.sh
# Comment out the counting steps.
bash run_pipeline.sh
```

But this process, and subsequently undoing it,
can be a hassle and source of errors for complicated pipelines.

What we really want is an executable _description_ of our pipeline that
allows software to do the tricky part for us:
figuring out what steps need to be re-run.
It would also be nice if this tool encourage a _modular_ analysis
and re-using instead of re-writing parts of our pipeline.
As an added benefit, we'd like it all to play nice with the other
mainstays of reproducible research: version control, UNIX style tools,
and a variety of scripting languages.


### `Makefile` basics ###

"Make" is a computer program originally designed to automate the compilation
and installation of software.
Make automates the process of building target files through a series of
discrete steps.
Despite it's original purpose, this design makes it a great fit for
bioinformatics pipelines, which often work by transforming data from one form
to another (e.g. _raw data_ to _word counts_ to _...?_ to _profit_).

For this tutorial we will be using an implementation of Make called
GNU Make, although others exist.


#### Simple Makefile ####

Let's get started writing a description of our analysis for Make.

Open up a file called `Makefile` in your editor of choice (e.g. `nano Makefile`)
and add the following:

```Makefile
isles.count.tsv: books/isles.txt
	./wordcount.py books/isles.txt isles.words.tsv
```

Here we have just about the simplest possible Makefile.

Be sure to notice a few syntactical items.

The part before the colon is called the **target** and the part after is our
list of **prerequisites**.
This first line is followed by an indented section called the **recipe**.
The whole thing is together called a **rule**.

Notice that the indent is _not_ multiple spaces, but is instead a single tab
character.
This is the first gotcha in Makefiles.
If the difference between spaces and a tab character isn't obvious in your
editor of choice, try moving your cursor from one side of the tab to the other.
It should _jump_ four or more spaces.
If your recipe is not indented with a tab character it is likely to not work.

Notice that this recipe is exactly the same as the analogous step in our
master shell script.
This is no coincidence; Make recipes _are_ shell scripts.
The first line (target : prerequisites) explicitly declares two details
that which were implicit in our pipeline script:

1.  We are generating a file called `isles.words.tsv`
2.  Creating this file requires `books/isles.txt`

We'll think about our pipeline as a network of files.
Right now, our Makefile says

> `isles.words.tsv` <-- `books/isles.txt`

where the arrow is pointing downstream, from requirements to targets.

Don't forget to commit.

```bash
git add Makefile
git commit -m "Start converting master script into a Makefile."
```

#### Running Make ####

Now that we have a (currently incomplete) description of our pipeline,
let's use Make to execute it.

First, remove the previously generated files.

```bash
rm *.words.tsv *.words.png
```

```bash
make isles.words.tsv
```

Quick aside:

Notice that we didn't tell Make to use `Makefile`.
When you run `make`, the program automatically looks in several places
for your Makefile.
While other filenames will work,
it is advisable to always call your Makefile `Makefile`.

/aside

You should see the following print to the terminal:

```
./wordcount.py books/isles.txt isles.words.tsv
```

By default, Make prints the recipes that it executes.

Let's see if we got what we expected.

```bash
head -5 isles.words.tsv
```

The first 5 lines of that file should look exactly like before.


#### Re-running Make ####

Let's try running Make the same way again.

```bash
make isles.words.tsv
```

This time, instead of executing the same recipe,
Make prints `make: Nothing to be done for 'isles.words.tsv'.`

What's happening here?

When you ask Make to make the target `isles.words.tsv` it first looks at
the modification time.
Next it looks at the modification time for its prerequisites.
If the target is newer than the prerequisites Make decides that
the target is up-to-date and does not need to be remade.

Much has been said about using modification times as the cue for remaking
files.
This can be another Make gotcha, so keep it in mind.

If you want to induce the original behavior, you just have to
change the modification time of `books/isles.txt` so that it is newer
than `isles.words.tsv`.

```bash
touch books/isles.txt
make isles.words.tsv
```

The original behavior is restored.

Sometimes you just want Make to tell you what it thinks about the current
state of your files.
`make -n isles.words.tsv` will print Make's execution plan, without
actually carrying it out.

If you don't pass a target as an argument to make (i.e. just run `make`)
it will assume that you want to build the first target in the Makefile.

#### More recipes ####

Let's add a few more recipes to our Makefile.

```Makefile
abyss.words.tsv: books/abyss.txt
	./wordcount.py books/abyss.txt abyss.words.tsv

isles.words.png: isles.words.tsv
	./plotcount.py isles.words.tsv isles.words.png

zipf_results.tgz: isles.words.tsv abyss.words.tsv isles.words.png abyss.words.png
	tar -czf zipf_results.tgz isles.words.tsv abyss.words.tsv \
        isles.words.png abyss.words.png
```

And commit the changes.

```bash
git add Makefile
git commit -m "Add recipes for abyss counts, isles plotting, and the final archive."
```

Notice the backslash in the recipe for `zipf_results.tgz`.
Just like many other languages,
in Makefiles '\' is a line-continuation character.
Think of that recipe as a single line without the backslash.

> ### Question ###
> Without doing it, what happens if you run `make isles.words.png`?

> ### Challenge ###
> What does the dependency graph look like for this Makefile?

> ### Try it ###
> What happens if you run `make zipf_results.tgz` right now?

> ### Practice ###
> Write a recipe for `abyss.words.png`.


Once you've written a recipe for `abyss.words.png` you should be able to
run `make zipf_results.tgz`.

Let's delete all of our files and try it out.

```bash
rm abyss.* isles.*
make zipf_results.tgz
```

You should get the something like the following output
(the order may be different)
to your terminal:

```
./wordcount.py books/abyss.txt abyss.words.tsv
./wordcount.py books/isles.txt isles.words.tsv
./plotcount.py abyss.words.tsv abyss.words.png
./plotcount.py isles.words.tsv isles.words.png
tar -czf zipf_results.tgz isles.words.tsv \
        abyss.words.tsv isles.words.png abyss.words.png
```

Since you asked for `zipf_results.tgz` Make looked first for that file.
When it didn't find that file it looked for its prerequisites.
Since none of those existed it remade the ones it could,
`abyss.words.tsv` and `isles.words.tsv`.
Once those were finished it was able to make `abyss.words.png` and
`isles.words.png`, before finally building `zipf_results.tgz`.

> ### Try it ###
> What happens if you `touch abyss.words.tsv` and
> then `make zipf_results.tgz`?

```bash
git add Makefile
git commit -m "Finish translating pipeline script to a Makefile."
git status
```

Notice all the files that git wants to be tracking.
Add a `.gitignore` file:

```
*.words.tsv
*.words.png
zipf_results.tgz
```

```bash
git add .gitignore
git commit -m "Have git ignore intermediate data files."
git status
```


#### Convenience Recipes ####

Sometimes its nice to have targets which don't refer to actual files.

```Makefile
all: isles.words.png abyss.words.png zipf_results.tgz
```

Even though this rule doesn't have a recipe, it does have prerequisites.
Now, when you run `make all` Make will do what it needs to to bring
all three of those targets up to date.

It is traditional for `all:` to be the first recipe in a Makefile,
since the first recipe is what is built by default
when no other target is passed as an argument.

Another traditional target is `clean`.
Add the following to your Makefile.

```Makefile
clean:
	rm -f *.words.tsv *.words.png zipf_results.tgz
```

Running `make clean` will now remove all of the cruft.

Watch out, though!
What happens if you create a file named `clean` (i.e. `touch clean`)?
When you run `make clean` you get `make: Nothing to be done for 'clean'.`.
That's _not_ because all those files have already been removed.
Make isn't that smart.
Instead, make sees that there is already a file called `clean` and,
since `clean` is newer than all of its (non-existent) prerequisites
Make decides there's nothing left to do.

To avoid this problem add the following to your Makefile.

```Makefile
.PHONY: all clean
```

This "special target" tells Make to assume that the targets "all", and "clean"
are _not_ real files.

```bash
git add Makefile
git commit -m "Added all and clean recipes."
```
