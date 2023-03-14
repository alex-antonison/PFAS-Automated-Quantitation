#' Calculate the Average Peak Ratio from the source data
#'
#' This uses the processed files from Set2_1_138_Short.XLS
#' This uses the Native_analyte_ISmatch_source.xlsx to match native analytes
#' to their corresponding internal standards
#'
#' Notes about calculations:
#' Issue: Found duplicate filenames for internal standards and native analytes. For some instances the peak areas are the same but some they are slightly different.
#' Resolution: Resolving this by first removing duplicates and then taking the highest peak area value.
#'
#'


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
  # remove duplicates
  dplyr::distinct_all() %>%
  # ranking to find the highest value of peak area
  dplyr::group_by(
    individual_native_analyte_name,
    source_file_name,
    filename,
    replicate_number,
    calibration_level
  ) %>%
  dplyr::mutate(
    calibration_rank = dplyr::row_number(dplyr::desc(individual_native_analyte_peak_area))
  ) %>%
  dplyr::ungroup() %>%
  dplyr::filter(calibration_rank == 1) %>%
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
  dplyr::distinct_all() %>%
  dplyr::group_by(
    internal_standard_name,
    source_file_name,
    filename
  ) %>%
  # identify instance with largest internal peak area
  dplyr::mutate(
    calibration_rank = dplyr::row_number(dplyr::desc(internal_standard_peak_area))
  ) %>%
  dplyr::ungroup() %>%
  # filter down to the highest peak area for a given internal standard + filename
  dplyr::filter(calibration_rank == 1) %>%
  dplyr::select(
    internal_standard_name,
    source_file_name,
    filename,
    internal_standard_peak_area
  )

individual_native_analyte_df %>%
  dplyr::left_join(native_analyte_internal_standard_mapping_df, by = "individual_native_analyte_name") %>%
  dplyr::left_join(internal_standard_df, by = c("internal_standard_name", "source_file_name", "filename")) %>%
  dplyr::mutate(
    analyte_peak_area_ratio = individual_native_analyte_peak_area / internal_standard_peak_area
  ) %>%
  dplyr::group_by(
    individual_native_analyte_name,
    internal_standard_name,
    calibration_level
  ) %>%
  dplyr::summarise(
    average_analyte_peak_area_ratio = mean(analyte_peak_area_ratio),
    .groups = "keep"
  ) %>%
  dplyr::ungroup() %>%
  arrow::write_parquet(
    sink = "data/processed/calibration-curve/average_peak_area_ratio.parquet"
  )
