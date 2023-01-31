setup_project:
	Rscript -e 'renv::install()'
	Rscript -e 'precommit::install_precommit()'
	Rscript -e 'precommit::use_precommit_config()'
