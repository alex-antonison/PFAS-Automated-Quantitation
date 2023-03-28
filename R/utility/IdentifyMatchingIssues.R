library(magrittr)

#########################
# Check Source Calibration Internal Standard to Native Analyte
#########################

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

check_df <- individual_native_analyte_df %>%
  dplyr::left_join(native_analyte_internal_standard_mapping_df, by = "individual_native_analyte_name") %>%
  dplyr::left_join(internal_standard_df, by = c("internal_standard_name", "source_file_name", "filename")) %>%
  dplyr::filter(is.na(internal_standard_peak_area))

# no issues found

#########################
# Check Concentration Table Matching
#########################

native_analyte_concentration_df <- arrow::read_parquet("data/processed/native_analyte_concentration.parquet")

internal_standard_concentration_df <- arrow::read_parquet("data/processed/internal_standard_concentration.parquet")

native_analyte_internal_standard_mapping_df <- arrow::read_parquet("data/processed/reference/native_analyte_internal_standard_mapping.parquet")

cal_name_native_analyte_mapping_df <- arrow::read_parquet("data/processed/reference/calibration_concentration_name_mapping.parquet")

match_df <- native_analyte_concentration_df %>%
  dplyr::rename(source_analyte_name = individual_native_analyte_name) %>%
  dplyr::left_join(cal_name_native_analyte_mapping_df, by = "source_analyte_name") %>%
  # dropping instances where there is not a mapped analyte name TODO
  dplyr::mutate(
    match_found = ifelse(is.na(individual_native_analyte_name),
      "no match found",
      "match found"
    )
  ) %>%
  dplyr::distinct(
    concentration_file_analyte_name = source_analyte_name,
    mapping_file_analyte_name = individual_native_analyte_name,
    match_found
  ) %>%
  as.data.frame() %>%
  xlsx::write.xlsx(
    "data/processed/troubleshoot/matching-issue/source_analyte_to_concentration_match_issue.xlsx",
    row.names = FALSE
  )

##################################
# Identify Matching Issues between Concentration Ratio and Average Peak Ratio
#################################

average_peak_area_ratio_df <- arrow::read_parquet("data/processed/calibration-curve/average_peak_area_ratio.parquet")

concentration_ratio_df <- arrow::read_parquet("data/processed/calibration-curve/concentration_ratio.parquet") %>%
  dplyr::select(
    individual_native_analyte_name,
    calibration_level,
    analyte_concentration_ratio
  )

average_peak_area_ratio_df %>%
  dplyr::left_join(
    concentration_ratio_df,
    by = c(
      "individual_native_analyte_name",
      "calibration_level"
    )
  ) %>%
  dplyr::mutate(
    concentration_ratio_match_found = ifelse(is.na(analyte_concentration_ratio),
      "no match found",
      "match found"
    )
  ) %>%
  dplyr::distinct(
    source_calibration_analyte_name = individual_native_analyte_name,
    concentration_ratio_match_found
  ) %>%
  readr::write_excel_csv(
    "data/processed/troubleshoot/matching-issue/source_calibration_analyte_to_concentratio_ratio_match_issue.csv"
  )


##################
# Identify Matching issues for Analyte Concentration Table
#################

peak_area_ratio <- arrow::read_parquet(
  "data/processed/quantify-sample/peak_area_ratio.parquet"
)

calibration_curve_output <- arrow::read_parquet(
  "data/processed/calibration-curve/calibration_curve_output.parquet"
) %>%
  dplyr::select(
    individual_native_analyte_name,
    slope,
    y_intercept,
    r_squared
  )

extraction_batch_source <- arrow::read_parquet(
  "data/processed/extraction_batch_source.parquet"
) %>%
  dplyr::select(
    batch_number,
    cartridge_number,
    internal_standard_used
  )

internal_standard_mix <- arrow::read_parquet(
  "data/processed/internal_standard_mix.parquet"
) %>%
  dplyr::select(
    internal_standard_used = internal_standard_mix,
    internal_standard_name = internal_standard_concentration_name,
    stock_mix,
    internal_standard_concentration_ppb
  )


temp_df <- peak_area_ratio %>%
  dplyr::left_join(
    calibration_curve_output,
    by = "individual_native_analyte_name"
  ) %>%
  dplyr::left_join(
    extraction_batch_source,
    by = c("batch_number", "cartridge_number")
  )
