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
source("R/process-source-data/ProcessRawData.R")

native_analyte_internal_standard_mapping_df <- arrow::read_parquet("data/processed/reference/native_analyte_internal_standard_mapping.parquet")

individual_native_analyte_df <- arrow::read_parquet("data/processed/source/source_data_individual_native_analyte.parquet") %>%
  dplyr::select(
    individual_native_analyte_name,
    source_file_name,
    filename,
    replicate_number,
    calibration_level,
    individual_native_analyte_peak_area
  ) %>%
  # remove exact duplicates
  dplyr::distinct_all() %>%
  # ranking to find the highest value of peak area
  dplyr::group_by(
    individual_native_analyte_name,
    source_file_name,
    filename,
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
    individual_native_analyte_name,
    source_file_name,
    filename,
    replicate_number,
    calibration_level,
    individual_native_analyte_peak_area
  )


internal_standard_df <- arrow::read_parquet("data/processed/source/source_data_internal_standard.parquet") %>%
  dplyr::select(
    internal_standard_name,
    source_file_name,
    filename,
    internal_standard_peak_area
  ) %>%
  # remove exact duplicates
  dplyr::distinct_all() %>%
  dplyr::group_by(
    internal_standard_name,
    source_file_name,
    filename
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
    internal_standard_name,
    source_file_name,
    filename,
    internal_standard_peak_area
  )

individual_native_analyte_df %>%
  # join the native analyte table to the internal standard to native analyte mapping table
  dplyr::left_join(native_analyte_internal_standard_mapping_df, by = "individual_native_analyte_name") %>%
  # with the internal standards mapped, join to the internal standard source data
  dplyr::left_join(internal_standard_df, by = c("internal_standard_name", "source_file_name", "filename")) %>%
  # calculate the analyte peak ratio
  dplyr::mutate(
    analyte_peak_area_ratio = individual_native_analyte_peak_area / internal_standard_peak_area
  ) %>%
  dplyr::group_by(
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
  readr::write_excel_csv(
    "data/processed/calibration-curve/average_peak_area_ratio.csv"
  )
