library(magrittr)

# suppress warnings
options(warn = -1)

section_change_print <- function(section_name) {
  print("=========================")
  print(paste0("Processing ", section_name))
  print("=========================")
}

########################################
section_change_print("Processing Source Data")
########################################

source("R/process-source-data/RefCreateMappingFiles.R")
source("R/process-source-data/ProcessCalibrationCurveSourceFile.R")
source("R/process-source-data/ProcessConfigurationFiles.R")
source("R/process-source-data/ProcessExtractionBatchSource.R")
source("R/process-source-data/ProcessInternalStandardMixFile.R")
source("R/process-source-data/ProcessQCBlankFiltering.R")
source("R/process-source-data/ProcessQCSampleFile.R")


# This can take time depending on volume of data, only uncomment if you need
# to re-process source data files
# source("R/process-source-data/ProcessRawData.R")

########################################
section_change_print("Building Calibration Curve")
########################################

source("R/build-calibration-curve/1_CalculateAveragePeakRatio.R")
source("R/build-calibration-curve/1_CalculateConcentrationRatio.R")
source("R/build-calibration-curve/2_BuildCalibrationCurveInput.R")
source("R/build-calibration-curve/3_CalculateCalibrationCurve.R")

########################################
section_change_print("Quantify Sample")
########################################

# load in a list of filenames in source data to ignore
source("R/quantify-sample/ignore_list.R")

# quantifying sample
source("R/quantify-sample/1_BuildSamplePeakAreaRatio.R")
source("R/quantify-sample/2_BuildLimitOfDetectionReference.R")
source("R/quantify-sample/3_CalculateAnalyteConcentration.R")

########################################
section_change_print("Build Data Products")
########################################

source("R/build-data-products/1_BuildExtractionBlank.R")
source("R/build-data-products/2_RemoveExtractionBlankFromAnalyteConcentration.R")
source("R/build-data-products/3_1_BuildQualityControlTable.R")
source("R/build-data-products/3_2_RemoveFieldBlanksFromBlankFilteredAnalyte.R")
source("R/build-data-products/4_EvaluateQualityControlSamples.R")
source("R/build-data-products/5_Calculate_Analyte_Concentration_ppt.R")
