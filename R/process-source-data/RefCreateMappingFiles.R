#' This script creates a more streamlined version of
#' the data/source/Native_analyte_ISmatch_source.xlsx for use in
#' calculations.

create_reference_mapping_file <- function(){

  ############################
  # Create Native Analyte to Internal Standard Reference File
  ###########################
  
  readxl::read_excel(
    "data/source/mapping/Native_analyte_ISmatch_source.xlsx",
    sheet = "Sheet1"
  ) %>%
    janitor::clean_names() %>%
    dplyr::mutate(
      cal_level_loq = readr::parse_number(cal_level_loq),
      cal_level_lod = readr::parse_number(cal_level_lod)
    ) %>%
    dplyr::select(
      individual_native_analyte_name = processing_method_name,
      internal_standard_name = internal_standard,
      cal_level_loq,
      cal_level_lod,
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

}