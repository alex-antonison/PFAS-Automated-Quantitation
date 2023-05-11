#' This script creates a more streamlined version of
#' the data/source/Native_analyte_ISmatch_source.xlsx for use in
#' calculations.

library(magrittr)

############################
# Get Source Reference Files
###########################

full_file_list <- c(
  "data/source/mapping/Native_analyte_ISmatch_source.xlsx",
  "data/source/mapping/analyte_concentration_name_mapping.xlsx",
  "data/source/mapping/internal_standard_concentration_name_mapping.xlsx"
)

# setting this to false
missing_file <- FALSE

for (file_path in full_file_list) {
  if (!fs::file_exists(file_path)) {
    # if a source file is missing, this will trigger
    # downloading source data from S3
    missing_file <- TRUE
  }
}

# if a file is missing pull source data from S3
if (missing_file) {
  source("R/utility/GetSourceData.R")
} else {
  # if all files are downloaded, skip downloading data
  print("Source Data Downloaded")
}

############################
# Create Native Analyte to Internal Standard Reference File
###########################

readxl::read_excel(
  "data/source/mapping/Native_analyte_ISmatch_source.xlsx",
  sheet = "Sheet1"
) %>%
  janitor::clean_names() %>%
  dplyr::mutate(
    cal_level_loq = readr::parse_number(cal_level_loq)
  ) %>%
  dplyr::select(
    individual_native_analyte_name = processing_method_name,
    internal_standard_name = internal_standard,
    cal_level_loq
  ) %>%
  arrow::write_parquet(
    sink = "data/processed/mapping/native_analyte_internal_standard_mapping.parquet"
  ) %>% 
  readr::write_excel_csv(
    "data/processed/mapping/native_analyte_internal_standard_mapping.csv"
  )

############################
# Create Calibration Analyte Name to Source Analyte Name Reference File
###########################

readxl::read_excel("data/source/mapping/analyte_concentration_name_mapping.xlsx") %>%
  janitor::clean_names() %>%
  dplyr::rename(
    source_analyte_name = individual_native_analyte_name,
    individual_native_analyte_name = corresponding_name_in_native_analyte_ismatch_source
  ) %>%
  arrow::write_parquet(
    sink = "data/processed/mapping/analyte_concentration_name_mapping.parquet"
  ) %>% 
  readr::write_excel_csv(
    "data/processed/mapping/analyte_concentration_name_mapping.csv"
  )

############################
# Create Calibration Internal Standard Name to Source Analyte Name Reference File
###########################

readxl::read_excel(
  "data/source/mapping/internal_standard_concentration_name_mapping.xlsx"
) %>%
  arrow::write_parquet(
    sink = "data/processed/mapping/concentration_internal_standard_mapping.parquet"
  ) %>% 
  readr::write_excel_csv(
    "data/processed/mapping/concentration_internal_standard_mapping.csv"
  )
