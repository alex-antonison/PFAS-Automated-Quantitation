analysis-file:
	Rscript R/Create_Analysis_Summary_File.R

main:
	Rscript R/main.R

clean-code:
	Rscript StyleCode.R

setup:
	Rscript setup.R