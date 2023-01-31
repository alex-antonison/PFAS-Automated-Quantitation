# process-mass-spec-data

## Dev Setup

* To initialize the project, please use R 4.2.2 and use `renv::install()` to install the necessary packages.
* This project uses the [lintr](https://github.com/r-lib/lintr) for checking for code quality.
* This project uses [https://github.com/lorenzwalthert/precommit](https://github.com/lorenzwalthert/precommit) pre-commit hooks to streamline code quality and management.
* This project uses [styler](https://styler.r-lib.org/) to auto-format code.

### pre-commit

Set up pre-commit with

```R
install.packages("remotes")
remotes::install_github("lorenzwalthert/precommit")
```
### setup project:

Run `make setup_proejct`

This will run the following 3 R comamnds:

* `Rscript -e 'install.packages("renv")'`: Installs renv which is used for package management
* `Rscript -e 'renv::install()'`: Installs packages contained in renv configuration file.
* `Rscript -e 'precommit::install_precommit()'`: Installs pre-commit if you do not already have it
* `Rscript -e 'precommit::use_precommit_config()'`: Installs a standard pre-commit config

To see pre-commit files in R Studio, need to select the option `More > Show Hidden Files`

### renv setup

* Used `renv::settings$snapshot.type("all")` to capture all packages installed in project.

### GitHub Actions

From [https://github.com/r-lib/actions/tree/v2-branch/examples#style-package](https://github.com/r-lib/actions/tree/v2-branch/examples#style-package), using the following github actions:

* `usethis::use_github_action("render-rmarkdown")`
* `usethis::use_github_action("style")`
* `usethis::use_github_action("lint-project")`
