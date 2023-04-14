#' Calculate the Average Peak Ratio from the source data
#'
#' This uses the largest peak area for each native analyte and internal standard
#' for a given replicate and calibration level.
#'
#' With the largest peak area found, the native analyte will be joined with its corresponding
#' internal standard, replicate, and calibration level to calculate the ratio.
#'
#' The average for each calibration level will then be calculated.
#'
#' This uses the processed files from Set2_1_138_Short.XLS
#' This uses the Native_analyte_ISmatch_source.xlsx to match native analytes
#' to their corresponding internal standards
#'
#' Notes about calculations:
#' Issue: Found duplicate filenames for internal standards and native analytes. For some instances the peak areas are the same but some they are slightly different.
#' Resolution: Resolving this by first removing duplicates and then taking the highest peak area value.
#'
#' Input:
#'    Data:
#'     - Raw Analyte Peak values filtered down to calibration filename
#'     - Raw Internal Standard Peak values filtered down to calibration filename
#'
#'    Ref:
#'     - Mapping file to tie native analytes to internal standards
#'
#' Ouput: Average Peak Area Ratio
#'
#'
#' Note:
#'
#' When there are duplicate filenames - this could be as a result of mid-run
#' when the person running the mass spec needs to restart, they would start where
#' they left off. We take the highest value in the event that when finding the
#' area under the curve, they do ignore it because it is a duplicate filename.

source("R/process-source-data/RefCreateMappingFiles.R")

library(magrittr)

####################################
# Build raw data tables
####################################

####################################
# Create Analyte Calibration Table
####################################

combined_data_df <- arrow::read_parquet(
  "data/processed/source/full_raw_data.parquet"
)

# create_analyte_table <- function(df) {
temp_analyte_df <- combined_data_df %>%
  dplyr::filter(source_type == "native_analyte") %>%
  # filter down to analytes that have a match in the reference file
  dplyr::filter(analyte_match == "Match Found") %>%
  # filter down to cal values
  dplyr::filter(
    stringr::str_detect(stringr::str_to_lower(filename), "cal")
  ) %>%
  dplyr::mutate(
    # calculate the length of the analyte name to trim the number
    # off the end
    analyte_name_length = stringr::str_length(sheet_name),
    # remove the _# from the end of the analyte name
    analyte_name = stringr::str_sub(sheet_name, 0, analyte_name_length - 2),
    # capture the transition number
    transition_number = stringr::str_sub(sheet_name, -1),
    underscore_count = stringr::str_count(filename, "_")
  ) %>%
  # only interested in the first transition for an analyte
  dplyr::filter(transition_number == 1) %>%
  # only filenames with values that are not NF
  dplyr::filter(area != "NF") %>%
  # convert area to numeric
  dplyr::mutate(
    individual_native_analyte_peak_area = as.numeric(area)
  )

without_rep_number_df <- temp_analyte_df %>%
  dplyr::filter(underscore_count == 1) %>%
  dplyr::mutate(
    replicate_number = 1,
    split_filename = stringr::str_split_fixed(filename, "_", 2),
    calibration_level = as.integer(split_filename[, 2])
  ) %>%
  dplyr::select(
    batch_number,
    individual_native_analyte_name = analyte_name,
    replicate_number,
    calibration_level,
    individual_native_analyte_peak_area
  )

with_rep_number_df <- temp_analyte_df %>%
  dplyr::filter(underscore_count == 2) %>%
  dplyr::filter(!stringr::str_detect(filename, "rep")) %>%
  dplyr::mutate(
    split_filename = stringr::str_split_fixed(filename, "_", 3),
    replicate_number = as.integer(split_filename[, 2]),
    calibration_level = as.integer(split_filename[, 3])
  ) %>%
  dplyr::select(
    batch_number,
    individual_native_analyte_name = analyte_name,
    replicate_number,
    calibration_level,
    individual_native_analyte_peak_area
  )

dplyr::bind_rows(
  without_rep_number_df,
  with_rep_number_df
) %>%
  readr::write_csv(
    "data/processed/source/source_data_individual_native_analyte.csv"
  ) %>%
  arrow::write_parquet(
    sink = "data/processed/source/source_data_individual_native_analyte.parquet"
  )

####################################
# Create Internal Standard Calibration Table
####################################

temp_ind_df <- combined_data_df %>%
  # filter down to internal_standard
  dplyr::filter(source_type == "internal_standard") %>%
  # filter down to cal levels
  dplyr::filter(
    stringr::str_detect(stringr::str_to_lower(filename), "cal")
  ) %>%
  # only filenames with values that are not NF
  dplyr::filter(area != "NF") %>%
  dplyr::mutate(
    internal_standard = sheet_name,
    underscore_count = stringr::str_count(filename, "_"),
    internal_standard_peak_area = as.numeric(area)
  )


temp_ind_without_rep_df <- temp_ind_df %>%
  dplyr::filter(underscore_count == 1) %>%
  dplyr::mutate(
    replicate_number = 1,
    split_filename = stringr::str_split_fixed(filename, "_", 2),
    calibration_level = as.integer(split_filename[, 2])
  ) %>%
  dplyr::select(
    batch_number,
    internal_standard_name = internal_standard,
    replicate_number,
    calibration_level,
    internal_standard_peak_area
  )

temp_ind_with_rep_df <- temp_ind_df %>%
  dplyr::filter(underscore_count == 2) %>%
  dplyr::filter(!stringr::str_detect(filename, "rep")) %>%
  dplyr::mutate(
    split_filename = stringr::str_split_fixed(filename, "_", 3),
    replicate_number = as.integer(split_filename[, 2]),
    calibration_level = as.integer(split_filename[, 3])
  ) %>%
  dplyr::select(
    batch_number,
    internal_standard_name = internal_standard,
    replicate_number,
    calibration_level,
    internal_standard_peak_area
  )

dplyr::bind_rows(
  temp_ind_without_rep_df,
  temp_ind_with_rep_df
) %>%
  readr::write_csv(
    "data/processed/source/source_data_internal_standard.csv"
  ) %>%
  arrow::write_parquet(
    sink = "data/processed/source/source_data_internal_standard.parquet"
  )
############################### Start Calculating Average Peak Ratio #####################

native_analyte_internal_standard_mapping_df <- arrow::read_parquet(
  "data/processed/mapping/native_analyte_internal_standard_mapping.parquet"
  )

individual_native_analyte_df <- arrow::read_parquet("data/processed/source/source_data_individual_native_analyte.parquet") %>%
  dplyr::select(
    batch_number,
    individual_native_analyte_name,
    replicate_number,
    calibration_level,
    individual_native_analyte_peak_area
  ) %>%
  # remove exact duplicates
  dplyr::distinct_all() %>%
  # ranking to find the highest value of peak area
  dplyr::group_by(
    batch_number,
    individual_native_analyte_name,
    replicate_number,
    calibration_level
  ) %>%
  # calculate the highest value area (desc)
  dplyr::mutate(
    peak_area_rank = dplyr::row_number(dplyr::desc(individual_native_analyte_peak_area))
  ) %>%
  dplyr::ungroup() %>%
  # filter down to the row that has the highest peak area
  dplyr::filter(peak_area_rank == 1) %>%
  dplyr::select(
    batch_number,
    individual_native_analyte_name,
    replicate_number,
    calibration_level,
    individual_native_analyte_peak_area
  )


internal_standard_df <- arrow::read_parquet("data/processed/source/source_data_internal_standard.parquet") %>%
  dplyr::select(
    batch_number,
    internal_standard_name,
    replicate_number,
    calibration_level,
    internal_standard_peak_area
  ) %>%
  # remove exact duplicates
  dplyr::distinct_all() %>%
  dplyr::group_by(
    batch_number,
    internal_standard_name,
    replicate_number,
    calibration_level
  ) %>%
  # rank internal standard + source file name + filename to identify the row with
  # the greatest peak area
  dplyr::mutate(
    peak_area_rank = dplyr::row_number(dplyr::desc(internal_standard_peak_area))
  ) %>%
  dplyr::ungroup() %>%
  # filter down to the highest peak area for a given internal standard + filename
  dplyr::filter(peak_area_rank == 1) %>%
  dplyr::select(
    batch_number,
    internal_standard_name,
    replicate_number,
    calibration_level,
    internal_standard_peak_area
  )

individual_native_analyte_df %>%
  # join the native analyte table to the internal standard to native analyte mapping table
  dplyr::left_join(native_analyte_internal_standard_mapping_df, by = "individual_native_analyte_name") %>%
  # with the internal standards mapped, join to the internal standard source data
  dplyr::left_join(
    internal_standard_df,
    by = c(
      "batch_number",
      "internal_standard_name",
      "replicate_number",
      "calibration_level"
    )
  ) %>%
  # calculate the analyte peak ratio
  dplyr::mutate(
    analyte_peak_area_ratio = individual_native_analyte_peak_area / internal_standard_peak_area
  ) %>%
  dplyr::group_by(
    batch_number,
    individual_native_analyte_name,
    internal_standard_name,
    calibration_level
  ) %>%
  # take the average for each calibration level
  dplyr::summarise(
    average_peak_area_ratio = mean(analyte_peak_area_ratio),
    .groups = "keep"
  ) %>%
  dplyr::ungroup() %>%
  arrow::write_parquet(
    sink = "data/processed/calibration-curve/average_peak_area_ratio.parquet"
  ) %>%
  readr::write_csv(
    "data/processed/calibration-curve/average_peak_area_ratio.csv"
  )
