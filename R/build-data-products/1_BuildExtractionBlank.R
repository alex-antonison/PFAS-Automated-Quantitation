library(magrittr)

extraction_batch_source <- arrow::read_parquet(
  "data/processed/reference/extraction_batch_source.parquet"
)

analyte_concentration_df <- arrow::read_parquet(
  "data/processed/quantify-sample/analyte_concentration_with_recovery.parquet"
)

analyte_peak_area <- analyte_concentration_df %>%
  dplyr::select(
    batch_number,
    cartridge_number,
    individual_native_analyte_name,
    analyte_detection_flag,
    internal_standard_name,
    internal_standard_detection_flag,
    calibration_curve_range_category,
    analyte_concentration_ng
  )


extraction_blank <- analyte_peak_area %>%
  dplyr::left_join(
    extraction_batch_source,
    by = c("batch_number", "cartridge_number")
  ) %>%
  # filter down to Extraction Blanks
  dplyr::filter(stringr::str_detect(county, "Extraction Blank")) %>% 
  dplyr::mutate(
    new_analyte_concentration_ng = dplyr::if_else(
      (analyte_detection_flag),
      analyte_concentration_ng,
      0.0
    )
  ) %>% 
  dplyr::select(
    batch_number,
    cartridge_number,
    county,
    individual_native_analyte_name,
    calibration_curve_range_category,
    analyte_concentration_ng,
    new_analyte_concentration_ng
  ) # %>% 
  # dplyr::filter(batch_number == 2)

# Extraction Blank Check
extraction_blank %>% 
  dplyr::group_by(
    batch_number,
    individual_native_analyte_name
  ) %>% 
  dplyr::summarise(
    blank_count = dplyr::n()
  )
