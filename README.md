---
title: (GNU)Make for reproducible bioinformatics pipelines
author: Byron J. Smith

---

This is the repository for a lesson on Make for bioinformatics pipelines at
Titus Brown's 2016 Workshop at Bodega Marine Labs

## TODO ##

-   [x] License
-   [ ] Port portions of the SWC Make lesson
-   [ ] Write out learning objectives
-   [ ] Consider what concept/challenge questions to use during the lesson
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
-   Students understand when Make is _not_ the best choice for organizing a
    project (e.g. super compute-heavy workflows, building flexible tools, etc.)
-   Students are inspired to make their workflows "reproducible" from the
    start, using a variety of tools, including Make.
-   Students know how to build-in testing to their workflows, both unit and
    integration.
