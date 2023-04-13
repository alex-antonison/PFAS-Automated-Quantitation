#' Building the Peak Area Ratio Table with Samples
#'
#' This will use the the samples from the source data
#'
#' Input:
#'   Data:
#'     data/processed/source/sample_individual_native_analyte.parquet
#'     data/processed/source/sample_internal_standard.parquet
#'  Reference:
#'     data/processed/reference/native_analyte_internal_standard_mapping.parquet
#'
#' Output:
#'   data/processed/quantify-sample/peak_area_ratio.parquet

library(magrittr)

source("R/process-source-data/RefCreateMappingFiles.R")

####################################
# Create Analyte Sample Table
####################################

combined_data_df <- arrow::read_parquet(
  "data/processed/source/full_raw_data.parquet"
)

combined_data_df %>%
  dplyr::filter(source_type == "native_analyte") %>%
  # filter down to analytes that have a match in the reference file
  dplyr::filter(analyte_match == "Match Found") %>%
  # filter down to only filenames that have a number
  dplyr::filter(!grepl("\\D", filename)) %>%
  # only filenames with values that are not NF
  # dplyr::filter(area != "NF") %>%
  dplyr::mutate(
    # rename to cartridge_number for joining later
    cartridge_number = filename,
    # convert peak area to numeric
    individual_native_analyte_peak_area = as.numeric(area),
    # calculate analyte name
    analyte_name_length = stringr::str_length(sheet_name),
    individual_native_analyte_name = stringr::str_sub(sheet_name, 0, analyte_name_length - 2),
    # calculate transition number
    transition_number = stringr::str_sub(sheet_name, -1)
  ) %>%
  # filter to transition 1
  dplyr::filter(transition_number == 1) %>%
  dplyr::select(
    batch_number,
    individual_native_analyte_name,
    cartridge_number,
    individual_native_analyte_peak_area
  ) %>%
  arrow::write_parquet(
    sink = "data/processed/source/sample_individual_native_analyte.parquet"
  ) %>%
  readr::write_excel_csv(
    "data/processed/source/sample_individual_native_analyte.csv"
  )

####################################
# Create Internal Standard Sample Table
####################################

combined_data_df %>%
  dplyr::filter(source_type == "internal_standard") %>%
  # filter down to only filenames that are a number
  dplyr::filter(!grepl("\\D", filename)) %>%
  # only filenames with values that are not NF
  # dplyr::mutate(
  #   detection_flag = if NF == Not Detected, if not NF Detected
  # )
  dplyr::filter(area != "NF") %>%
  dplyr::mutate(
    internal_standard_name = sheet_name,
    # rename to cartridge_number for joining later
    cartridge_number = filename,
    # convert peak area to numeric
    internal_standard_peak_area = as.numeric(area)
  ) %>%
  dplyr::select(
    batch_number,
    internal_standard_name,
    cartridge_number,
    internal_standard_peak_area
  ) %>%
  arrow::write_parquet(
    sink = "data/processed/source/sample_internal_standard.parquet"
  ) %>%
  readr::write_excel_csv(
    "data/processed/source/sample_internal_standard.csv"
  )

################### Start Calculation for Sample Peak Area Ratio

sample_native_analyte_df <- arrow::read_parquet(
  "data/processed/source/sample_individual_native_analyte.parquet"
)


sample_internal_standard_df <- arrow::read_parquet(
  "data/processed/source/sample_internal_standard.parquet"
)

native_analyte_internal_standard_mapping_df <- arrow::read_parquet(
  "data/processed/reference/native_analyte_internal_standard_mapping.parquet"
)

sample_native_analyte_df %>%
  dplyr::left_join(
    native_analyte_internal_standard_mapping_df,
    by = "individual_native_analyte_name"
  ) %>%
  dplyr::left_join(
    sample_internal_standard_df,
    by = c("batch_number", "internal_standard_name", "cartridge_number")
  ) %>%
  dplyr::mutate(
    # calculate the peak area ratio
    peak_area_ratio = individual_native_analyte_peak_area / internal_standard_peak_area
  ) %>%
  arrow::write_parquet(
    sink = "data/processed/quantify-sample/peak_area_ratio.parquet"
  ) %>%
  readr::write_excel_csv(
    "data/processed/quantify-sample/peak_area_ratio.csv"
  )
