---
title: Reproducible bioinformatics pipelines using _Make_
author: Byron J. Smith

---

# Setup [15 minutes] #

[AWS?]

For this lesson we will be using an already prepared set of files.

```bash
curl https://codeload.github.com/bsmith89/make-example/zip/master \
    > make-example-master.zip
unzip make-example-master.zip
cd make-example-master
```

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


# Motivation [30 minutes] #

> The most frequently-occurring word occurs approximately twice as
> often as the second most frequent word. This is
> [Zipf's Law](http://en.wikipedia.org/wiki/Zipf%27s_law).

Let's imagine that instead of computational biology we're interested in
testing Zipf's law in some of our favorite books.
We've compiled our raw data, the books we want to analyze
(check out `head books/isles.txt`)
and have prepared several Python scripts that together make up our
analysis pipeline.

Before we begin, add a README to your project describing what we intend
to do.

```bash
nano README.md
# Describe what you're going to do. (e.g. "Test Zipf's Law")
```

The first step is to count the frequency of each word in the book.

```bash
./wordcount.py books/isles.txt isles.dat
```

Let's take a quick peek at the result.

```bash
head -5 isles.dat
```

shows us the top 5 lines in the output file:

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
./wordcount.py books/abyss.txt abyss.dat
head -5 abyss.dat
```

Finally, let's visualize the results.

```bash
./plotcount.py isles.dat ascii
```

The `ascii` argument has been added so that we get a text-based
bar-plot printed to the screen.

The script is also able to display a graphical bar-plot using matplotlib.

```bash
./plotcount.py isles.dat show
```

Or it can save the figure as a file.

```bash
./plotcount.py isles.dat isles.png
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
a master script that runs the whole pipeline from start to finish.

We can make a new file, `run_pipeline.sh` that contains:

```bash
#!/usr/bin/env bash
# USAGE: bash run_pipeline.sh
# to produce plots for isles and abyss.

./wordcount.py isles.txt isles.dat
./wordcount.py abyss.txt abyss.dat

./plotcount.py isles.dat isles.png
./plotcount.py abyss.dat abyss.png

# Now archive the results in a tarball so we can share them with a colleague.
tar -czf zipf_results.tgz isles.dat abyss.dat \
    isles.png abyss.png
```

This master script solved several problems in computational reproducibility:

1.  It explicitly documents our pipeline,
    making communication with colleagues (and our future selves) more efficient.
2.  It allows us to type a single command, `bash run_pipeline.sh`, to
    reproduce the full analysis.
3.  It prevents us from _repeating_ typos or mistakes.
    You might not get it right the first time, but once you fix something
    it'll (probably) stay that way.

To continue with the Good Ideas, let's put everything under version control.

```bash
git init
git add README.md
git commit -m "Starting a new project."
git add wordcount.py plotcount.py
git commit -m "Write scripts to test Zipf's law."
git add run_pipeline.sh
git commit -m "Write a master script to run the pipeline."
```

Notice that I didn't version control any of the products of our analysis.
I'll talk more about this later.

A master script is a good start, but it has a few shortcomings.

Let's imagine that we adjusted the width of the bars in our plot.
produced by `plotcount.py`.

```bash
nano plotcount.py
# In the definition of plot_word_counts replace:
#    width = 1.0
# with:
#    width = 0.8
git add plotcount.py
git commit -m "Fix the bar width."
```

Now we want to recreate our figures.
We _could_ just `bash run_pipeline.sh` again.
That would work, but it could also be a big pain if counting words takes
more than a few seconds.
The the word counting routine hasn't changed; we shouldn't need to recreate
those files.

Alternatively, we could manually rerun the plotting for each word-count file
and recreate the tarball.

```bash
for file in *.dat; do
    ./plotcount.py $file ${file/.dat/.png}
done

tar -czf zipf_results.tgz isles.dat abyss.dat \
    isles.png abyss.png
```

But then we don't get many of the benefits of having a master script in
the first place.

Another popular option is to comment out a subset of the lines in
`run_pipeline.sh`:

```bash
#!/usr/bin/env bash
# USAGE: bash run_pipeline.sh
# to produce plots for isles and abyss.

# These lines are commented out because they don't need to be rerun.
#./wordcount.py isles.txt isles.dat
#./wordcount.py abyss.txt abyss.dat

./plotcount.py isles.dat isles.png
./plotcount.py abyss.dat abyss.png

# Now archive the results in a tarball so we can share them with a colleague.
tar -czf zipf_results.tgz isles.dat abyss.dat \
    isles.png abyss.png
```

Followed by `bash run_pipeline.sh`.

But this process, and subsequently undoing it,
can be a hassle and source of errors in complicated pipelines.

[Revise this part]

What we really want is an executable _description_ of our pipeline that
allows software to do the tricky part for us:
figuring out what steps need to be rerun.
It would also be nice if this tool encourage a _modular_ analysis
and reusing instead of rewriting parts of our pipeline.
As an added benefit, we'd like it all to play nice with the other
mainstays of reproducible research: version control, Unix-style tools,
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
isles.dat: books/isles.txt
	./wordcount.py books/isles.txt isles.dat
```

We have now written the simplest, non-trivial Makefile.
It is pretty reminiscent of one of the lines from our master script.
It is a good bet that you can figure out what this Makefile does.

Be sure to notice a few syntactical items.

The part before the colon is called the **target** and the part after is our
list of **prerequisites** (there is just one in this case).
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

1.  We are generating a file called `isles.dat`
2.  Creating this file requires `books/isles.txt`

We'll think about our pipeline as a network of files that are dependent
on one another.
Right now our Makefile describes a pretty simple **dependency graph**.

> `books/isles.txt` &#8594; `isles.dat`

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
rm *.dat *.png
```

```bash
make isles.dat
```

> #### Aside ####
>
> Notice that we didn't tell _Make_ to use `Makefile`.
> When you run `make`, the program automatically looks in several places
> for your Makefile.
> While other filenames will work,
> it is Good Idea to always call your Makefile `Makefile`.

You should see the following print to the terminal:

```
./wordcount.py books/isles.txt isles.dat
```

By default, _Make_ prints the recipes that it executes.

Let's see if we got what we expected.

```bash
head -5 isles.dat
```

The first 5 lines of that file should look exactly like before.


## Rerunning _Make_ ##

Let's try running _Make_ the same way again.

```bash
make isles.dat
```

This time, instead of executing the same recipe,
_Make_ prints `make: Nothing to be done for 'isles.dat'.`

What's happening here?

When you ask _Make_ to make `isles.dat` it first looks at
the modification time of that target.
Next it looks at the modification time for the target's prerequisites.
If the target is newer than the prerequisites _Make_ decides that
the target is up-to-date and does not need to be remade.

Much has been said about using modification times as the cue for remaking
files.
This can be another _Make_ gotcha, so keep it in mind.

If you want to induce the original behavior, you just have to
change the modification time of `books/isles.txt` so that it is newer
than `isles.dat`.

```bash
touch books/isles.txt
make isles.dat
```

The original behavior is restored.

Sometimes you just want _Make_ to tell you what it thinks about the current
state of your files.
`make --dry-run isles.dat` will print _Make_'s execution plan, without
actually carrying it out.
The flag can be abbreviated as `-n`.

If you don't pass a target as an argument to make (i.e. just run `make`)
it will assume that you want to build the first target in the Makefile.


## More recipes ##

Now that _Make_ knows how to build `isles.dat`,
we can add a rule for plotting those results.

```makefile
isles.png: isles.dat
	./plotcount.py isles.dat isles.png
```

The dependency graph now looks like:

> `books/isles.txt` &#8594; `isles.dat` &#8594; `isles.png`

Let's add a few more recipes to our Makefile.

```makefile
abyss.dat: books/abyss.txt
	./wordcount.py books/abyss.txt abyss.dat

zipf_results.tgz: isles.dat abyss.dat isles.png abyss.png
	tar -czf zipf_results.tgz isles.dat abyss.dat \
        isles.png abyss.png
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

> #### Question ####
> Without doing it, what happens if you run `make isles.png`?

> #### Challenge ####
> What does the dependency graph look like for your Makefile?

> #### Try it ####
> What happens if you run `make zipf_results.tgz` right now?

> #### Practice ####
> Write a recipe for `abyss.png`.

Once you've written a recipe for `abyss.png` you should be able to
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
./wordcount.py books/abyss.txt abyss.dat
./wordcount.py books/isles.txt isles.dat
./plotcount.py abyss.dat abyss.png
./plotcount.py isles.dat isles.png
tar -czf zipf_results.tgz isles.dat \
        abyss.dat isles.png abyss.png
```

Since you asked for `zipf_results.tgz` _Make_ looked first for that file.
Not finding it, _Make_ looked for its prerequisites.
Since none of those existed it remade the ones it could,
`abyss.dat` and `isles.dat`.
Once those were finished it was able to make `abyss.png` and
`isles.png`, before finally building `zipf_results.tgz`.

> #### Try it ####
> What happens if you `touch abyss.dat` and
> then `make zipf_results.tgz`?

```bash
git add Makefile
git commit -m "Finish translating pipeline script to a Makefile."
git status
```

Notice all the files that _Git_ wants to be tracking?
Like I said before, we're not going to version control any of the intermediate
or final products of our pipeline.
To reflect this fact add a `.gitignore` file:

```.gitignore
*.dat
*.png
zipf_results.tgz
LICENSE.md
```

```bash
git add .gitignore
git commit -m "Have git ignore intermediate data files."
git status
```


## Phony targets ##

Sometimes its nice to have targets that don't refer to actual files.

```makefile
all: isles.png abyss.png zipf_results.tgz
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
	rm --force *.dat *.png zipf_results.tgz
```

Running `make clean` will now remove all of the cruft.

Watch out, though!

> #### Try it ####
>
> What happens if you create a file named `clean` (i.e. `touch clean`)
> and then run `make clean`?

When you run `make clean` you get `make: Nothing to be done for 'clean'.`.
That's _not_ because all those files have already been removed.
_Make_ isn't that smart.
Instead, make sees that there is already a file named "`clean`" and,
since this file is newer than all of its prerequisites (there are none),
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
git commit -m "Added 'all' and 'clean' recipes."
```


# _Make_ features [45 minutes] #

Right now our Makefile looks like this:

```makefile
# Dummy targets
all: isles.png abyss.png zipf_results.tgz

clean:
	rm --force *.dat *.png zipf_results.tgz

.PHONY: all clean

# Analysis and plotting
isles.dat: books/isles.txt
	./wordcount.py books/isles.txt isles.dat

isles.png: isles.dat
	./plotcount.py isles.dat isles.png

abyss.dat: books/abyss.txt
	./wordcount.py books/abyss.txt abyss.dat

abyss.png: abyss.png
	./plotcount.py abyss.dat abyss.png

# Archive for sharing
zipf_results.tgz: isles.dat abyss.dat isles.png abyss.png
	tar -czf zipf_results.tgz isles.dat abyss.dat \
        isles.png abyss.png
```

Look's good, don't you think?
Notice the added comments, starting with the "`#`" character just like in
Python, R, shell, etc.

Using these recipes, a simple call to `make` builds all the same files that
we were originally making either manually or using the master script,
but with a few bonus features.

Now, if we change one of the inputs, we don't have to rebuild everything.
Instead, _Make_ knows to only rebuild the files that, either directly or
indirectly, depend on the file that changed.
This is called an **incremental build**.
It's no longer our job to track those dependencies.
One fewer cognitive burden getting in the way of research progress!

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
`abyss.dat` and `isles.dat` are mutually independent and can
both be built at the same time.
Likewise for `abyss.png` and `isles.png`.
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
Our current makefile does _not_ conform to this principle,
but _Make_ is perfectly capable of solving the problem.


## Automatic variables ##

One overly repetitive part of our Makefile:
Targets and prerequisites are in both the header _and_ the recipe of each rule.

It turns out, that

```makefile
isles.dat: books/isles.txt
	./wordcount.py books/isles.txt isles.dat
```

can be rewritten as

```makefile
isles.dat: books/isles.txt
	./wordcount.py $^ $@
```

Here we've replaced the prerequisite "`books/isles.txt`" in the recipe
with "`$^`" and the target "`isles.dat`" with "`$@`".
Both "`$^`" and "`$@`" are variables that refer to all of the prerequisites and
target of a rule, respectively.
In _Make_, variables are referenced with a leading dollar sign symbol.
While we can also define our own variables,
_Make_ _automatically_ defines a number of variables, including each of these.

```makefile
zipf_results.tgz: isles.dat abyss.dat isles.png abyss.png
	tar -czf zipf_results.tgz isles.dat abyss.dat \
        isles.png abyss.png
```

can now be rewritten as

```makefile
zipf_results.tgz: isles.dat abyss.dat isles.png abyss.png
	tar -czf $@ $^
```

Phew!  That's much less cluttered,
and still perfectly understandable once you know what the variables mean.

> #### Try it ####
>
> ```bash
> make clean
> make isles.dat
> ``````````
<!--Those extra backticks are because of Vim syntax highlighting.-->

You should get the same output as last time.
Internally, _Make_ replaced "`$@`" with "`isles.dat`"
and "`$^`" with "`books/isles.txt`"
before running the recipe.

> #### Practice ####
>
> Go ahead and rewrite all of the rules in your Makefile to minimize
> repetition and take advantage of these automatic variables.
> Don't forget to commit your work.


## Pattern rules ##

Another deviation from D.R.Y.:
We have nearly identical recipes for `abyss.dat` and `isles.dat`.

It turns out we can replace _both_ of those rules with just one rule,
by telling _Make_ about the relationships between filename _patterns_.

A "pattern rule" looks like this:

```makefile
%.dat: books/%.txt
	countwords.py $^ $@
```

Here we've replaced the book name with a percent sign, "`%`".
The "`%`" is called the **stem**
and matches any sequence of characters in the target.
(Kind of like a "`*`" (glob) in a path name, but they are _not_ the same.)
Whatever it matches is then filled in to the prerequisites
wherever there's a "`%`".

This rule can be interpretted as:

> In order to build a file named `[something].dat` (the target)
> find a file named `books/[that same something].txt` (the prerequisite)
> and run `countwords.py [the prerequisite] [the target]`.

Notice how helpful the automatic variables are here.
This recipe will work no matter what stem is being matched!

We can replace _both_ of the rules that matched this pattern
(`abyss.dat` and `isles.dat`) with just one rule.
Go ahead and do that in your Makefile.

> #### Try it ####
>
> After you've replaced the two rules with one pattern
> rule, try removing all of the products (`make clean`)
> and rerunning the pipeline.
>
> Is anything different now that you're using the pattern rule?
>
> If everything still works, commit your changes to _Git_.

> #### Practice ####
>
> Replace the recipes for `abyss.png` and `isles.png`
> with a single pattern rule.

> #### Challenge ####
>
> Add `books/sierra.txt` to your pipeline.
>
> (i.e. `make all` should plot the word counts and add the plots to
> `zipf_results.tgz`)

Commit your changes to _Git_ before we move on.


## User defined variables ##

Not all variables in a makefile are of the automatic variety.
Users can define their own, as well.

Add this lines at the top of your makefile:

```makefile
ARCHIVED := isles.dat isles.png \
            abyss.dat abyss.png \
            sierra.dat sierra.png
```

The variable `ARCHIVED` is a list of the files that we want to include in our
tarball.
Now wherever we write `${ARCHIVED}` it will be replaced with that list of files.
The dollar sign, "`$`", and curly-braces, "`{}`", are both mandatory when
inserting the contents of a variable.

Notice the backslashes in the variable definition
splitting the list over three lines, instead of one very long line.
Also notice that we assigned to the variable with "`:=`".
This is generally a Good Idea;
Assigning with a normal equals sign can result in non-intuitive behavior
(for reasons we may not talk about).
Finally, notice that the items in our list are separated by _whitespace_,
not commas.
Prerequisite lists were the same way; this is just how lists of things work in
makefiles.
If you included commas they would be considered parts of the filenames.

Using this variable we can replace the prerequisites of `zipf_results.tgz`.
That rule would now be:

```makefile
zipf_results.tgz: ${ARCHIVED}
	tar -czf $@ $^
```

We can also use `${OBJECTS}` to simplify our cleanup rule.

```makefile
clean:
	rm --force ${ARCHIVED} zipf_results.tgz
```

> #### Try it ####
>
> Try running `clean` and then `all`.
>
> Does everything still work?


# Best practices for _Make_-based projects [60 minutes] #

A Makefile can be an important part of a reproducible research pipeline.
Have you noticed how simple it is now to add/remove books from our analysis?
Just add or remove those files from the definition of `ARCHIVED` or
the prerequisites for the `all` target!
With the master script `run_pipeline.sh`,
adding a third book required either more complicated
or less transparent changes.


## What's a prerequisite? ##

We've talked a lot about the power of _Make_ for
rebuilding research outputs when input data changes.
When doing novel data analysis, however, it's very common for our _scripts_ to
be as or _more_ dynamic than the data.

What happens when we edit our scripts instead of changing our data?

> #### Try it ####
>
> First, run `make all` so your analysis is up-to-date.
>
> Let's change the default number of entries in the rank/frequency
> plot from 10 to 5.
>
> (Hint: edit the function definition for `plot_word_counts` in
> `plotcounts.py` to read `limit=5`.)
>
> Now run `make all` again.  What happened?

As it stands, we have to run `make clean` followed by `make all`
to update our analysis with the new script.
We're missing out on the benefits of incremental analysis when our scripts
are changing too.

There must be a better way...and there is!  Scripts should be prerequisites too.

Let's edit the pattern rule for `%.png` to include `plotcounts.py`
as a prerequisites.

```makefile
%.png: plotcounts.py %.dat
	$^ $@
```

The header makes sense, but that's a strange looking recipe:
just two automatic variables.

This recipe works because "`$^`" is replaced with all of the prerequisites.
_In order_.
When building `abyss.png`, for instance, it is replaced with
`plotcounts.py abyss.dat`, which is actually exactly what we want.

> #### Try it ####
>
> What happens when you run the pipeline after modifying your script again?
>
> (Changes to your script can be simulated with `touch plotcounts.py`.)

> #### Practice ####
>
> Update your other rules to include the relevant scripts as prerequisites.
>
> Commit your changes.


## Directory structure ##

Take a look at all of the clutter in your project directory (run `ls` to
list all of the files).
For such a small project that's a lot of junk!
Imagine how hard it would be to find your way around this analysis
if you had more than three steps?
Let's move some stuff around to make our project easier to navigate.

### Store scripts in `scripts/` ###

First we'll stow away the scripts.

```
mkdir scripts/
mv plotcounts.py wordcount.py scripts/
```

We also need to update our Makefile to reflect the change:

```makefile
%.dat: countwords.py books/%.txt
	$^ $@

%.png: plotcounts.py %.dat
	$^ $@
```

becomes:

```makefile
%.dat: scripts/countwords.py books/%.txt
	$^ $@

%.png: scripts/plotcounts.py %.dat
	$^ $@
```

That's a little more verbose, but it is now explicit
that `countwords.py` and `plotcount.py` are scripts.

_Git_ should have no problem with the move once you tell it which files
to be aware of.

```bash
git add countwords.py plotcounts.py
git add scripts/countwords.py scripts/plotcounts.py
git add Makefile
git commit -m "Move scripts into a subdirectory."
```

Great!  From here on, when we add new scripts to our analysis they won't
clutter up our project root.

### "Hide" intermediate files in `data/` ###

Speaking of clutter, what are we gonna do about all of these intermediate files!?
Put 'em in a subdirectory!

```bash
mkdir data/
mv *.tsv data/
```

And then fix up your Makefile.
Adjust the relevant lines to look like this.

```makefile
# ...

ARCHIVED := data/isles.dat isles.png \
            data/abyss.dat abyss.png \
            data/sierra.dat sierra.png

# ...

data/%.dat: scripts/countwords.py books/%.txt
	$^ $@

%.png: scripts/plotcounts.py data/%.dat

# ...
```

Thanks to our `ARCHIVED` variable, making these changes is pretty simple.

We have to make one more change if we don't want _Git_ to bother us about
untracked files.
Update your `.gitignore`.

```.gitignore
data/*.dat
*.png
zipf_results.tgz
LICENSE.md
```

Now commit your changes.

```bash
git add Makefile
git add .gitignore
```

Simple!


### Output finished products to `fig/` ###

> #### Practice ####
>
> Move the plots and `zipf_results.tgz` to a directory called `fig/`.

You can call this directory something else if you prefer, but `fig/` seems
short and descriptive.

> #### Try it ####
>
> Does your pipeline still execute the way you expect?


## File naming ##

### Use file extensions to indicate format ###

Up to this point, we've been working with three types of data files,
each with it's own file extension.

-   '`.txt`' files: the original book in plain-text
-   '`.dat`' files: word counts and percentages in a plain-text format
-   '`.png`' files: PNG formatted barplots

Using file extensions like these clearly indicates to anyone not familiar with
your project what software to view each file with;
you won't get much out of opening a PNG with a text editor.
Whenever possible, use a widely used extension to make it easy for others
to understand your data.

File extensions also give us a handle for describing the flow of data in our
pipeline.
Pattern rules rely on this convention.
Our makefile says that the raw, book data feeds into word count data
which feeds into barplot data.

But the current naming scheme has one obvious ambiguity:
'`.dat`' isn't particularly descriptive.
Lots of file formats can be described as "data", including binary formats
that would require specialized software to view.
For tab-delimited, tabular data (data in rows and columns),
'`.tsv`' is a more precise convention.

Updating our pipeline to use this extension is as simple as find-and-replace
'`.dat`' to '`.tsv`' in our Makefile.
If you're tired of `mv`-ing your files everytime you change your pipeline
you can also `make clean` followed by `make all` to check that everything still
works.

You might want to update your "`clean`" recipe to remove all the junk
like so:

```makefile
clean:
	rm -f data/* fig/*
```

Be sure to commit all of your changes.

### Infix processing hints ###

One of our goals in implementing best practices for our analysis pipeline
is to make it easy to change it without rewriting everything.
Let's add a preprocessing step to our analysis that puts
everything in lowercase before counting words.

The program `tr` (short for "translate") is a Unix-style filter that swaps one
set of characters for another.
`tr '[:upper:]' '[:lower:]' < [input file] > [output file]`
will read the mixedcase input file and write all lowercase to
the output file.

We can add this to our pipeline by first adding a rule.
We know the recipe is going to look like this:

```makefile
tr '[:upper:]' '[:lower:]' < $^ > $@
```

> #### Challenge ####
>
> Rewrite your Makefile to update the pipeline with the preprocessing step.

You probably decided to take the pattern `books/%.txt` as the prerequisite,
but what did you opt to name the target?

`data/%.txt` is an option, but that means we have two files named
`[bookname].txt`, one in `books/` and one in `data/`.
Probably not the easiest to differentiate.

A better option is to use a more descriptive filename.

```makefile
data/%.lower.txt: books/%.txt
	tr '[:upper:]' '[:lower:]' < $^ > $@
```

By including an **infix** of `.lower.` in our filename it's easy to
see that one file is a lowercase version of the mixedcase original.
Now we can extend our pipeline with a variety of pre- and post-processing
steps, give each of them a descriptive infix,
and the names will be a self-documenting record of its origins.

For reasons which will be explained in a minute, let's also make a dummy
preprocessing step which will just copy the books verbatim into our
`data/` directory.

```makefile
data/%.txt: books/%.txt
	cp $^ $@
```

And, in the spirit of infixes, we'll rename `data/%.tsv` to be more descriptive.

```makefile
data/%.counts.tsv: scripts/wordcount.py data/%.txt
	$^ $@

fig/%.counts.png: scripts/plotcount.py data/%.counts.tsv
    $^ $@
```

Here's the _full_ Makefile:

> ```makefile
> ARCHIVED := data/isles.lower.counts.tsv data/abyss.lower.counts.tsv \
>         data/sierra.lower.counts.tsv fig/isles.lower.counts.png \
>         fig/abyss.lower.counts.png fig/sierra.lower.counts.png
>
> # Dummy targets
> all: fig/isles.lower.counts.png fig/abyss.lower.counts.png \
>         fig/sierra.lower.counts.png zipf_results.tgz
>
> clean:
> 	rm --force data/* fig/*
>
> .PHONY: all clean
>
> # Analysis and plotting
> data/%.txt: books/%.txt
> 	cp $^ $@
>
> data/%.lower.txt: data/%.txt
> 	tr '[:upper:]' '[:lower:]' < $^ > $@
>
> data/%.counts.tsv: scripts/wordcount.py data/%.txt
> 	$^ $@
>
> fig/%.counts.png: scripts/plotcount.py data/%.counts.tsv
> 	$^ $@
>
> # Archive for sharing
> zipf_results.tgz: ${ARCHIVED}
> 	tar -czf $@ $^
> ``````````
<!--Those extra backticks are because of Vim syntax highlighting.-->

Our filenames are certainly more verbose now, but in exchange we get:

1.  self-documenting filenames
2.  more flexible development
3.  and something else, too...

```bash
make clean
make fig/abyss.lower.counts.png fig/abyss.counts.png
```

What happened there?
We just built two different barplots, one for our analysis _with_ the
preprocessing step and one _without_.
Both from the same Makefile.
By liberally applying pattern rules and infix filenames
we get something like a "filename language".
We describe the analyses we want to run and then have _Make_ figure out the
details.

We can make this a tiny bit easier

> #### Practice ####
>
> Update your drawing of the dependency graph.


## Builtin Testing ##

It's a Good Idea to check your analysis against some form of ground truth.
The simplest version of this is a well-defined dataset that you can
reason about independent of your code.
Let's make just such a dataset.
Let's write a book!

Into a file called `books/test.txt` add something like this:

```
My Book
By Me

This is a book that I wrote.

The END

```

We don't need software to count all of the words in this book, and
we can probably imagine exactly what a barplot of the count would look like.
If the actual result doesn't look like we expected,
then there's probably something wrong with our analysis.
Testing your scripts with this tiny book is computationally cheap, too.

Let's try it out!

```bash
make fig/test.lower.counts.png
less data/test.lower.counts.tsv
```

Does your counts data match what you expected?

We should run this test for just about every change we make,
to our scripts or to our Makefile.
We're going to do that a _lot_ so we'll make it as easy as possible.

```makefile
test: fig/test.lower.counts.png

.PHONY: test clean all
```

You could even add the `test` phony target as the first thing in your Makefile.
That way just calling `make` will run your tests.

> #### Practice ####
>
> Add a cleanup target called `testclean` which is specific for
> the outputs of your test run.

Commit your changes, including `books/test.txt`.

```bash
git add Makefile
git add -f books/test.txt
git commit -m "Add pipeline testing recipe and book."
```


-   What do we version control?
-   Bootstrap your setup using _Make_
-   Download your data using _Make_
-   Debugging?
