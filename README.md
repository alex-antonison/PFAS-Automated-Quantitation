# process-mass-spec-data

## Overview

## Dev Setup

### R Setup

Set install R Version 4.2.2. It is recommended to use [rig](https://github.com/r-lib/rig)

### Project Setup

1. Spin up R Studio or an R Console with R 4.2.2
2. There is a file [setup.R](./setup.R) that includes a list of commands that will set a project up. To run it, you can do Run `source("setup.R")` in the R Console.

To see pre-commit files in R Studio, need to select the option `More > Show Hidden Files`

### code formatting

This project uses [styler](https://styler.r-lib.org/) to auto-format code.

### linting

This project uses the [lintr](https://github.com/r-lib/lintr) for checking for code quality.

### renv setup

* Used `renv::settings$snapshot.type("all")` to capture all packages installed in project.

### pre-commit

This project uses pre-commits from [https://github.com/lorenzwalthert/precommit](https://github.com/lorenzwalthert/precommit)

### GitHub Actions

From [https://github.com/r-lib/actions/tree/v2-branch/examples](https://github.com/r-lib/actions/tree/v2-branch/examples), using the following github actions:

* `usethis::use_github_action("render-rmarkdown")`
* `usethis::use_github_action("style")`
* `usethis::use_github_action("lint-project")`
