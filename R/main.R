library(magrittr)
options(warn=-1)

section_change_print <- function(section_name) {
  print("=========================")
  print(paste0("Processing ", section_name))
  print("=========================")
}

section_change_print("Processing Source Data")

source("R/process-source-data/ProcessCalibrationCurveSourceFile.R")
source("R/process-source-data/ProcessConfigurationFiles.R")
source("R/process-source-data/ProcessExtractionBatchSource.R")
source("R/process-source-data/ProcessInternalStandardMixFile.R")
source("R/process-source-data/ProcessQCBlankFiltering.R")
source("R/process-source-data/ProcessQCSampleFile.R")
source("R/process-source-data/RefCreateMappingFiles.R")

# This can take time depending on volume of data, only uncomment if you need
# to re-process source data files
# source("R/process-source-data/ProcessRawData.R")
