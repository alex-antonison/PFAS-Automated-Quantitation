setup_project:
	Rscript -e 'install.packages("renv")'
	Rscript -e 'renv::install()'
	Rscript -e 'precommit::install_precommit()'
	Rscript -e 'precommit::use_precommit_config()'
