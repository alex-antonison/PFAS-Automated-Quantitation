# ProcessMassSpecData

## Overview

## Dev Setup

### R Setup

* Set install R Version 4.2.2. It is recommended to use [rig](https://github.com/r-lib/rig)
* Install RStudio on Mac via [Homebrew](https://brew.sh/) (`brew install --cask rstudio`)

### Project Setup

1. Spin up R Studio or an R Console with R 4.2.2 (with the command `rig rstudio {R Version}` and for Mac, `rig rstudio 4.2-arm64`)
2. There is a file [setup.R](./setup.R) that includes a list of commands that will set a project up. To run it, you can do Run `source("setup.R")` in the R Console.

To see pre-commit files in R Studio, need to select the option `More > Show Hidden Files`

### Package Management

Packages are both managed with the DESCRIPTION file and specifically installed version with an renv.lock file. 

* When adding a package, you should use `usethis::use_package("{PackageName}", min_version = TRUE)` to add it to the DESCRIPTION file.
* You need to install the package with `renv::install("{PackageName}"")`
* You also need to perform an `renv::snapshot()` to update the renv.lock file.

### code formatting

This project uses [styler](https://styler.r-lib.org/) to auto-format code.

### renv setup

* Used `renv::settings$snapshot.type("explicit")` to manage packages using the DESCRIPTION file.

## Future

### Setup pre-commit

Setup pre-commits from [https://github.com/lorenzwalthert/precommit](https://github.com/lorenzwalthert/precommit)

### Setup GitHub Actions

Setup GitHub Actions, some examples are here: [https://github.com/r-lib/actions/tree/v2-branch/examples](https://github.com/r-lib/actions/tree/v2-branch/examples):

* `usethis::use_github_action("render-rmarkdown")`
* `usethis::use_github_action("style")`
* `usethis::use_github_action("lint-project")`
