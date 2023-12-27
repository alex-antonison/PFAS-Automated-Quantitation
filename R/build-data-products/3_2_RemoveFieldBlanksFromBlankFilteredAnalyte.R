library(magrittr)

extraction_batch_source <- arrow::read_parquet(
  "data/processed/reference/extraction_batch_source.parquet"
)

extraction_blank_filtered_analyte_concentration_df <- arrow::read_parquet(
  "data/processed/build-data-products/blank_filtered_analyte_concentration_no_recovery.parquet"
)

average_field_blank_analyte_concentration_df <- extraction_batch_source %>%
  dplyr::filter(county == "Field Blank") %>%
  dplyr::left_join(
    extraction_blank_filtered_analyte_concentration_df,
    by = c("batch_number", "cartridge_number")
  ) %>%
  dplyr::select(
    batch_number, cartridge_number, individual_native_analyte_name, extraction_blank_filtered_analyte_concentration_ng
  ) %>%
  dplyr::filter(!is.na(individual_native_analyte_name)) %>%
  dplyr::mutate(
    extraction_blank_filtered_analyte_concentration_ng = ifelse(
      is.na(extraction_blank_filtered_analyte_concentration_ng),
      0.0,
      extraction_blank_filtered_analyte_concentration_ng
    )
  ) %>%
  dplyr::group_by(
    individual_native_analyte_name
  ) %>%
  dplyr::summarise(
    average_field_blank_analyte_concentration_ng = mean(extraction_blank_filtered_analyte_concentration_ng),
    stdev_field_blank_analyte_concentration_ng = sd(extraction_blank_filtered_analyte_concentration_ng),
    percent_rsd_field_blank_analyte_concentration_ng = (stdev_field_blank_analyte_concentration_ng / average_field_blank_analyte_concentration_ng) * 100,
    .groups = "keep"
  ) %>%
  readr::write_excel_csv("data/processed/build-data-products/field_blank_analyte_concentration_average_ng.csv") %>%
  arrow::write_parquet(
    "data/processed/build-data-products/field_blank_analyte_concentration_average_ng.parquet"
  )


extraction_blank_filtered_analyte_concentration_df %>%
  dplyr::left_join(
    average_field_blank_analyte_concentration_df,
    by = c("individual_native_analyte_name")
  ) %>%
  dplyr::mutate(
    final_filtered_analyte_concentration_ng = extraction_blank_filtered_analyte_concentration_ng - average_field_blank_analyte_concentration_ng
  ) %>%
  dplyr::select(
    batch_number,
    cartridge_number,
    individual_native_analyte_name,
    final_filtered_analyte_concentration_ng
  ) %>%
  readr::write_excel_csv(
    paste0("data/processed/build-data-products/field_blank_blank_filtered_analyte_concentration_no_recovery.csv")
  ) %>%
  arrow::write_parquet(
    "data/processed/build-data-products/field_blank_blank_filtered_analyte_concentration_no_recovery.parquet"
  )
