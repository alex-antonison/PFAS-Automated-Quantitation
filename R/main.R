library(magrittr)

# suppress warnings
options(warn = -1)

section_change_print <- function(section_name) {
  print("=========================")
  print(paste0("Processing ", section_name))
  print("=========================")
}

process_raw_data <- TRUE

########################################
section_change_print("Processing Source Data")
########################################

print("Creating Mapping Files")
source("R/process-source-data/RefCreateMappingFiles.R")

print("Creating Calibration Curve Source")
source("R/process-source-data/ProcessCalibrationCurveSourceFile.R")

print("Creating Configuration Files")
source("R/process-source-data/ProcessConfigurationFiles.R")

print("Creating Extraction Batch Source")
source("R/process-source-data/ProcessExtractionBatchSource.R")

print("Creating Internal Standard Mix File")
source("R/process-source-data/ProcessInternalStandardMixFile.R")

print("Creating QC Blank Filtering")
source("R/process-source-data/ProcessQCBlankFiltering.R")

print("Creating QC Sample File")
source("R/process-source-data/ProcessQCSampleFile.R")

if (process_raw_data) {
  tictoc::tic("Processing Raw Data")
  print("Processing Raw Data - can take some time")
  source("R/process-source-data/ProcessRawData.R")
  tictoc::toc()
} else {
  print("========================")
  print("Skipping Processing Raw Data....")
  print("========================")
}

########################################
section_change_print("Building Calibration Curve")
########################################

print("Calculating Average Peak Ratio")
source("R/build-calibration-curve/1_CalculateAveragePeakRatio.R")

print("Calculating Concentration Ratio")
source("R/build-calibration-curve/1_CalculateConcentrationRatio.R")

print("Build Calibration Curve Input")
source("R/build-calibration-curve/2_BuildCalibrationCurveInput.R")

print("Calculate Calibration Curve")
source("R/build-calibration-curve/3_CalculateCalibrationCurve.R")

########################################
section_change_print("Quantify Sample")
########################################

# load in a list of filenames in source data to ignore
source("R/quantify-sample/ignore_list.R")

# quantifying sample
print("Build Sample Peak Area Ratio")
source("R/quantify-sample/1_BuildSamplePeakAreaRatio.R")

print("Build Limit of Detection Reference")
source("R/quantify-sample/2_BuildLimitOfDetectionReference.R")

print("Calculate Analyte Concentration")
source("R/quantify-sample/3_CalculateAnalyteConcentration.R")

########################################
section_change_print("Build Data Products")
########################################

print("Build Extraction Blank")
source("R/build-data-products/1_BuildExtractionBlank.R")

print("Remove Extraction Blank from Analyte Concentration")
source("R/build-data-products/2_RemoveExtractionBlankFromAnalyteConcentration.R")

print("Build Quality Control Table")
source("R/build-data-products/3_BuildQualityControlTable.R")

print("Evaluate Quality Control Samples")
source("R/build-data-products/4_EvaluateQualityControlSamples.R")

print("Remove Field Blanks from Blank Filtered Analyte")
source("R/build-data-products/5_RemoveFieldBlanksFromBlankFilteredAnalyte.R")

print("Calculate Final Analyte Concentration")
source("R/build-data-products/6_Calculate_Analyte_Concentration_ppt.R")
