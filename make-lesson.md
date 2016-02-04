---
title: Reproducible bioinformatics pipelines using _Make_
author: Byron J. Smith

---

# Setup [15 minutes] #

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


# Motivation [15 minutes] #

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

## Writing a "master" script ##

Running this pipeline for one book is pretty easy using the command-line.
But once the number of files and the number of steps in the pipeline
expands, this can turn into a lot of work.
Plus, no one wants to sit and wait for a command to finish, even just for 30
seconds.

The most common solution to the tedium of data processing is to write
a master script which runs the whole pipeline from start to finish.

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

To continue with the Good Ideas, let's put everything under version control.

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

Now we want to recreate our figures.
We _could_ just `bash run_pipeline.sh` again.
That would work, but it could also be a big pain if counting words takes
more than a few seconds.

Alternatively, we could manually rerun the plotting for each word-count file
and recreate the tarball.

```bash
for file in *.words.tsv; do
    ./plotcount.py $file ${file/.tsv/.png}
done

tar -czf zipf_results.tgz isles.words.tsv abyss.words.tsv \
    isles.words.png abyss.words.png
```

But then we don't get many of the benefits of having a master script.

Another popular option is to comment out a subset of the lines in
`run_pipeline.sh`:

```bash
#!/usr/bin/env bash
# USAGE: bash run_pipeline.sh
# to produce plots for isles and abyss.

# These lines are commented out because they don't need to be rerun.
#./wordcount.py isles.txt isles.words.tsv
#./wordcount.py abyss.txt abyss.words.tsv
./plotcount.py isles.words.tsv isles.words.png
./plotcount.py abyss.words.tsv abyss.words.png

# Now archive the results in a tarball so we can share them with a colleague.
tar -czf zipf_results.tgz isles.words.tsv abyss.words.tsv \
    isles.words.png abyss.words.png
```

Followed by `bash run_pipeline.sh`.

But this process, and subsequently undoing it,
can be a hassle and source of errors for complicated pipelines.

What we really want is an executable _description_ of our pipeline that
allows software to do the tricky part for us:
figuring out what steps need to be rerun.
It would also be nice if this tool encourage a _modular_ analysis
and reusing instead of rewriting parts of our pipeline.
As an added benefit, we'd like it all to play nice with the other
mainstays of reproducible research: version control, UNIX style tools,
and a variety of scripting languages.


# Makefile basics [45 minutes] #

_Make_ is a computer program originally designed to automate the compilation
and installation of software.
_Make_ automates the process of building target files through a series of
discrete steps.
Despite it's original purpose, this design makes it a great fit for
bioinformatics pipelines, which often work by transforming data from one form
to another (e.g. _raw data_ &#8594; _word counts_ &#8594; _???_ &#8594; _profit_).

For this tutorial we will be using an implementation of _Make_ called
_GNU Make_, although others exist.


## A simple Makefile ##

Let's get started writing a description of our analysis for _Make_.

Open up a file called `Makefile` in your editor of choice (e.g. `nano Makefile`)
and add the following:

```makefile
isles.words.tsv: books/isles.txt
	./wordcount.py books/isles.txt isles.words.tsv
```

We have now written the simplest non-trivial Makefile.
It is pretty reminiscent of one of the lines from our master script.
I bet you can figure out what this Makefile does.

Be sure to notice a few syntactical items.

The part before the colon is called the **target** and the part after is our
list of **prerequisites**.
This first line is followed by an indented section called the **recipe**.
The whole thing is together called a **rule**.

Notice that the indent is _not_ multiple spaces, but is instead a single tab
character.
This is the first gotcha in makefiles.
If the difference between spaces and a tab character isn't obvious in your
editor of choice, try moving your cursor from one side of the tab to the other.
It should _jump_ four or more spaces.
If your recipe is not indented with a tab character it is likely to not work.

Notice that this recipe is exactly the same as the analogous step in our
master shell script.
This is no coincidence; _Make_ recipes _are_ shell scripts.
The first line (_target_: _prerequisites_) explicitly declares two details
that were implicit in our pipeline script:

1.  We are generating a file called `isles.words.tsv`
2.  Creating this file requires `books/isles.txt`

We'll think about our pipeline as a network of files which are dependent
on one another.
Right now our Makefile describes a pretty simple **dependency graph**.

> `books/isles.txt` &#8594; `isles.words.tsv`

where the "&#8594;" is pointing from requirements to targets.

Don't forget to commit:

```bash
git add Makefile
git commit -m "Start converting master script into a Makefile."
```

## Running _Make_ ##

Now that we have a (currently incomplete) description of our pipeline,
let's use _Make_ to execute it.

First, remove the previously generated files.

```bash
rm *.words.tsv *.words.png
```

```bash
make isles.words.tsv
```

> ### Aside ###
>
> Notice that we didn't tell _Make_ to use `Makefile`.
> When you run `make`, the program automatically looks in several places
> for your Makefile.
> While other filenames will work,
> it is Good Idea to always call your Makefile `Makefile`.

You should see the following print to the terminal:

```
./wordcount.py books/isles.txt isles.words.tsv
```

By default, _Make_ prints the recipes that it executes.

Let's see if we got what we expected.

```bash
head -5 isles.words.tsv
```

The first 5 lines of that file should look exactly like before.


## Rerunning _Make_ ##

Let's try running _Make_ the same way again.

```bash
make isles.words.tsv
```

This time, instead of executing the same recipe,
_Make_ prints `make: Nothing to be done for 'isles.words.tsv'.`

What's happening here?

When you ask _Make_ to make the target `isles.words.tsv` it first looks at
the modification time.
Next it looks at the modification time for its prerequisites.
If the target is newer than the prerequisites _Make_ decides that
the target is up-to-date and does not need to be remade.

Much has been said about using modification times as the cue for remaking
files.
This can be another _Make_ gotcha, so keep it in mind.

If you want to induce the original behavior, you just have to
change the modification time of `books/isles.txt` so that it is newer
than `isles.words.tsv`.

```bash
touch books/isles.txt
make isles.words.tsv
```

The original behavior is restored.

Sometimes you just want _Make_ to tell you what it thinks about the current
state of your files.
`make --dry-run isles.words.tsv` will print _Make_'s execution plan, without
actually carrying it out.
The flag can be abbreviated as `-n`.

If you don't pass a target as an argument to make (i.e. just run `make`)
it will assume that you want to build the first target in the Makefile.

## More recipes ##

Now that _Make_ knows how to build `isles.words.tsv`,
we can add a rule for plotting those results.

```makefile
isles.words.png: isles.words.tsv
	./plotcount.py isles.words.tsv isles.words.png
```

The dependency graph now looks like:

> `books/isles.txt` &#8594; `isles.words.tsv` &#8594; `isles.words.png`

Let's add a few more recipes to our Makefile.

```makefile
abyss.words.tsv: books/abyss.txt
	./wordcount.py books/abyss.txt abyss.words.tsv

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
in makefiles "`\`" is a line-continuation character.
Think of that recipe as a single line without the backslash.

> ### Question ###
> Without doing it, what happens if you run `make isles.words.png`?

> ### Challenge ###
> What does the dependency graph look like for your Makefile?

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

Since you asked for `zipf_results.tgz` _Make_ looked first for that file.
Not finding it, _Make_ looked for its prerequisites.
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


## Convenience recipes ##

Sometimes its nice to have targets which don't refer to actual files.

```makefile
all: isles.words.png abyss.words.png zipf_results.tgz
```

Even though this rule doesn't have a recipe, it does have prerequisites.
Now, when you run `make all` _Make_ will do what it needs to to bring
all three of those targets up to date.

It is traditional for "`all:`" to be the first recipe in a makefile,
since the first recipe is what is built by default
when no other target is passed as an argument.

Another traditional target is "`clean`".
Add the following to your Makefile.

```makefile
clean:
	rm --force *.words.tsv *.words.png zipf_results.tgz
```

Running `make clean` will now remove all of the cruft.

Watch out, though!

> ### Try it ###
>
> What happens if you create a file named `clean` (i.e. `touch clean`)
> and then run `make clean`?

When you run `make clean` you get `make: Nothing to be done for 'clean'.`.
That's _not_ because all those files have already been removed.
_Make_ isn't that smart.
Instead, make sees that there is already a file named "`clean`" and,
since this file is newer than all of its prerequisites
_Make_ decides there's nothing left to do.

To avoid this problem add the following to your Makefile.

```makefile
.PHONY: all clean
```

This "special target" tells _Make_ to assume that the targets "all", and "clean"
are _not_ real files;
they're **phony** targets.

```bash
git add Makefile
git commit -m "Added all and clean recipes."
```


# _Make_ features [45 minutes] #

Right now our Makefile looks like this:

```makefile
# Dummy targets
all: isles.words.png abyss.words.png zipf_results.tgz

clean:
	rm --force *.words.tsv *.words.png zipf_results.tgz

.PHONY: all clean

# Analysis and plotting
isles.words.tsv: books/isles.txt
	./wordcount.py books/isles.txt isles.words.tsv

isles.words.png: isles.words.tsv
	./plotcount.py isles.words.tsv isles.words.png

abyss.words.tsv: books/abyss.txt
	./wordcount.py books/abyss.txt abyss.words.tsv

abyss.words.png: abyss.words.png
    ./plotcount.py abyss.words.tsv abyss.words.png

# Archive for sharing
zipf_results.tgz: isles.words.tsv abyss.words.tsv isles.words.png abyss.words.png
	tar -czf zipf_results.tgz isles.words.tsv abyss.words.tsv \
        isles.words.png abyss.words.png
```

I'm pretty happy with it.  What about you?
Notice that I added comments, starting with the "`#`" character just like in
Python, R, shell, etc.

Using these recipes, a simple call to `make` builds all the same files that
we were originally making either manually or using the master script,
but with a few bonus features.

Now, if we change one of my inputs, we don't have to rebuild everything.
Instead, _Make_ knows to only rebuild the files which, either directly or
indirectly, depend on the file that changed.
It's no longer our job to track those dependencies.
One less cognitive burden getting in the way of making progress on our
analysis!

In addition, a makefile explicitly documents the inputs to and outputs
from every step in the analysis.
These are like informal "USAGE:" documentation for our scripts.

## Parallel _Make_ ##

And check this out!

```bash
make clean
make --jobs
```

Did you see it?
The `--jobs` flag (just `-j` works too) tells _Make_ to run recipes in _parallel_.
Our dependency graph clearly shows that
`abyss.words.tsv` and `isles.words.tsv` are mutually independent and can
both be built at the same time.
Likewise for `abyss.words.png` and `isles.words.png`.
If you've got a bunch of independent branches in your analysis, this can
greatly speed up your build process.

## D.R.Y. (Don't Repeat Yourself) ##

In many programming language, the bulk of the language features are there
to allow the programmer to describe long-winded computational routines as
short, expressive, beautiful code.
Features in Python or R like user-defined variables and functions are
useful in part because they mean we don't have to write out (or think about)
all of the details over and over again.
This good habit of writing things out only once is known as the D.R.Y.
principle.

In _Make_ a number of features are designed to minimize repetitive code.
Our current makefile does _not_ conform to this principle.
Turns out that _Make_ is perfectly capable of solving these problems.

## Automatic variables ##

One overly repetitive part of our Makefile:
Targets and prerequisites are in the header _and_ the recipe of each rule.

```makefile
isles.words.tsv: books/isles.txt
	./wordcount.py books/isles.txt isles.words.tsv
```

can be rewritten as

```makefile
isles.words.tsv: books/isles.txt
	./wordcount.py $^ $@
```

Here we've replaced the prerequisite "`books/isles.txt`" in the recipe
with "`$^`" and the target "`isles.words.tsv`" with "`$@`".
Both "`$^`" and "`$@`" are variables which refer to all of the prerequisites and
target of a rule, respectively.
In _Make_, variables are referenced with a leading dollar sign symbol.
While we can also define our own variables,
_Make_ _automatically_ defines a number of variables, including each of these.

```makefile
zipf_results.tgz: isles.words.tsv abyss.words.tsv isles.words.png abyss.words.png
	tar -czf zipf_results.tgz isles.words.tsv abyss.words.tsv \
        isles.words.png abyss.words.png
```

can now be rewritten as

```makefile
zipf_results.tgz: isles.words.tsv abyss.words.tsv isles.words.png abyss.words.png
	tar -czf $@ $^
```

Phew!  That's much less cluttered,
and still perfectly understandable once you know what the variables mean.

Try it out!

```bash
make clean
make isles.words.tsv
```

You should get the same output as last time.
Internally, _Make_ replaced "`$@`" with "`isles.words.tsv`"
and "`$^`" with "`books/isles.txt`"
before running the recipe.

> ### Practice ###
>
> Go ahead and rewrite all of the rules in your Makefile to minimize
> repetition and take advantage of these automatic variables.
> Don't forget to commit your work.

## Pattern rules ##

Another deviation from D.R.Y.:
We have nearly identical recipes for `abyss.words.tsv` and `isles.words.tsv`.

It turns out we can replace _both_ of those rules with just one rule,
by telling _Make_ about the relationships between filename _patterns_.

A "pattern rule" looks like this:

```makefile
%.words.tsv: books/%.txt
	countwords.py $^ $@
```

Here we've replaced the book name with a percent sign, "`%`".
The "`%`" is called the **stem**
and matches any sequence of characters in the target.
(Kind of like a "`*`" in a path name, but they are _not_ the same.)
Whatever it matches is then filled in to the prerequisites
wherever there's a "`%`".

This rule can be interpretted as:

> In order to build a file named `[something].words.tsv` (the target)
> find a file named `books/[that same something].txt` (the prerequisite)
> and run `countwords.py [the prerequisite] [the target]`.

Notice how helpful the automatic variables are here.
This recipe will work no matter what stem is being matched!

We can replace _both_ of the rules which matched this pattern
(`abyss.words.tsv` and `isles.words.tsv`) with just one rule.
Go ahead and do that in your Makefile.

> ### Try it ###
>
> After you've edited you've replaced the two rules with one pattern
> rule, try removing all of the products and rerunning the pipeline.
>
> Is anything different now that you're using the pattern rule?

> ### Practice ###
>
> Replace the recipes for `abyss.words.png` and `isles.words.png`
> with a single pattern rule.

> ### Challenge ###
>
> Add `books/sierra.txt` to your pipeline.
>
> (Plot the word counts and add the plots to `zipf_results.tgz`)
