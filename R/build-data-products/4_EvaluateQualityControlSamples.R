library(magrittr)

blank_filtered_analyte_concentration_quality_control <- arrow::read_parquet(
  "data/processed/build-data-products/blank_filtered_analyte_concentration_quality_control_no_recovery.parquet"
)


native_analyte_quality_control_levels <- arrow::read_parquet(
"data/processed/reference/native_analyte_quality_control_levels.parquet"
)


temp_df <- blank_filtered_analyte_concentration_quality_control %>% 
  dplyr::left_join(
    native_analyte_quality_control_levels,
    by = c("individual_native_analyte_name", "qc_level")
  ) %>% 
  dplyr::mutate(
    qc_recovery_ratio = (blank_filtered_average_qc_analyte_concentration_ng / native_analyte_spiked_in_qc_samples_ng) * 100
  ) %>% 
  dplyr::select(
    batch_number,
    individual_native_analyte_name,
    qc_level,
    blank_filtered_average_qc_analyte_concentration_ng,
    native_analyte_spiked_in_qc_samples_ng,
    qc_recovery_ratio
  ) %>% 
  readr::write_excel_csv(
    "data/processed/build-data-products/blank_filtered_evaluated_qc_no_recovery.csv"
  )
