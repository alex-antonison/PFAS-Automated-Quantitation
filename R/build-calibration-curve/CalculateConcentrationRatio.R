#' Calculate the Concentration Ratio
#'
#'

library(magrittr)

native_analyte_concentration_df <- arrow::read_parquet("data/processed/native_analyte_concentration.parquet")

internal_standard_concentration_df <- arrow::read_parquet("data/processed/internal_standard_concentration.parquet")

native_analyte_internal_standard_mapping_df <- arrow::read_parquet("data/processed/reference/native_analyte_internal_standard_mapping.parquet")

cal_name_native_analyte_mapping_df <- arrow::read_parquet("data/processed/reference/calibration_concentration_name_mapping.parquet")

native_analyte_concentration_df %>%
  dplyr::rename(source_analyte_name = individual_native_analyte_name) %>%
  dplyr::left_join(cal_name_native_analyte_mapping_df, by = "source_analyte_name") %>%
  # dropping instances where there is not a mapped analyte name TODO
  dplyr::filter(!is.na(individual_native_analyte_name)) %>%
  dplyr::left_join(native_analyte_internal_standard_mapping_df, by = c("individual_native_analyte_name")) %>%
  dplyr::left_join(internal_standard_concentration_df, by = c("internal_standard_name", "calibration_mix", "calibration_level")) %>%
  # remove instances where there are not mapped calibration values TODO
  dplyr::filter(!is.na(internal_standard_concentration_ppt)) %>%
  dplyr::mutate(
    analyte_concentration_ratio = native_analyte_concentration_ppt / internal_standard_concentration_ppt
  ) %>%
  dplyr::select(
    individual_native_analyte_name,
    internal_standard_name,
    calibration_level,
    analyte_concentration_ratio
  ) %>%
  dplyr::mutate(
    calibration_level = readr::parse_number(calibration_level)
  ) %>%
  arrow::write_parquet(
    sink = "data/processed/calibration-curve/concentration_ratio.parquet"
  ) %>%
  readr::write_excel_csv("data/processed/calibration-curve/concentration_ratio.csv")
