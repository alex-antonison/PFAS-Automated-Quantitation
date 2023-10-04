library(magrittr)

extraction_batch_source <- arrow::read_parquet(
  "data/processed/reference/extraction_batch_source.parquet"
)

blank_filtered_analyte_concentration <- arrow::read_parquet(
  "data/processed/build-data-products/blank_filtered_analyte_concentration_no_recovery.parquet"
)

field_blank_averaged_analyte_concentration <- extraction_batch_source %>%
  dplyr::filter(county == "Field Blank") %>%
  dplyr::left_join(
    blank_filtered_analyte_concentration,
    by = c("batch_number", "cartridge_number")
  ) %>%
  dplyr::select(
    batch_number, cartridge_number, individual_native_analyte_name, blank_filtered_analyte_concentration_ng
  ) %>%
  dplyr::filter(!is.na(individual_native_analyte_name)) %>% 
  dplyr::mutate(
    blank_filtered_analyte_concentration_ng = ifelse(
      is.na(blank_filtered_analyte_concentration_ng),
      0.0,
      blank_filtered_analyte_concentration_ng
    )
  ) %>% 
  dplyr::group_by(
    individual_native_analyte_name
  ) %>%
  dplyr::summarise(
    field_blank_average_analyte_concentration_ng = mean(blank_filtered_analyte_concentration_ng),
    field_blank_stdev_analyte_concentration_ng = sd(blank_filtered_analyte_concentration_ng),
    field_blank_percent_rsd_analyte_concentration_ng = (field_blank_stdev_analyte_concentration_ng / field_blank_average_analyte_concentration_ng) * 100
  ) %>%
  readr::write_excel_csv("data/processed/build-data-products/field_blank_analyte_concentration_average_ng.csv")


blank_filtered_analyte_concentration %>%
  dplyr::left_join(
    field_blank_averaged_analyte_concentration,
    by = c("individual_native_analyte_name")
  ) %>%
  dplyr::mutate(
    field_blank_blank_filtered_analyte_concentration_ng = blank_filtered_analyte_concentration_ng - field_blank_average_analyte_concentration_ng
  ) %>%
  dplyr::select(
    batch_number,
    cartridge_number,
    individual_native_analyte_name,
    field_blank_blank_filtered_analyte_concentration_ng
  ) %>%
  readr::write_excel_csv(
    paste0("data/processed/build-data-products/field_blank_blank_filtered_analyte_concentration_no_recovery.csv")
  )
