# process-mass-spec-data

## Dev Setup

1. Set install R Version 4.2.2. It is recommended to use [rig](https://github.com/r-lib/rig)
2. Use the following make command to setup the project `make setup_project`

### Makefile Description

Run `make setup_proejct`

This will run the following 3 R commands:

* `Rscript -e 'install.packages("renv")'`: Installs renv which is used for package management.
* `Rscript -e 'renv::install()'`: Installs packages contained in renv configuration file.
* `Rscript -e 'remotes::install_github("lorenzwalthert/precommit")'`: Installs the pre-commit package for streamlining setting up pre-commit.
* `Rscript -e 'precommit::install_precommit()'`: Installs pre-commit if you do not already have it.
* `Rscript -e 'precommit::use_precommit_config()'`: Installs a standard pre-commit config.

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
