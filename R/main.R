library(magrittr)

# Process Calibration Curve Source File
source("R/process-source-data/ProcessCalibrationCurveSourceFile.R")

process_cal_source("data/source/reference/Sep2021Calibration_Curve_source.xlsx")

# Process Configuration Files
source("R/process-source-data/ProcessConfigurationFiles.R")
process_config_files()

# Process Extraction Batch Source Files
source("R/process-source-data/ProcessExtractionBatchSource.R")

# Process IS_mix_source.xlsx file
process_is_excel("data/source/reference/IS_Mix_source.xlsx")