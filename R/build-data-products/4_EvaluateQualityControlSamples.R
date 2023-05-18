library(magrittr)

source("R/build-data-products/3_BuildQualityControlTable.R")
source("R/process-source-data/ProcessQCSampleFile.R")

eval_qc_for_blank_filtered_analyte <- function(blank_filtered_analyte_concentration_quality_control,
                                               native_analyte_quality_control_levels,
                                               file_name) {
  blank_filtered_analyte_concentration_quality_control %>%
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
      paste0("data/processed/build-data-products/blank_filtered_evaluated_qc_", file_name, ".csv")
    ) %>%
    arrow::write_parquet(
      sink = paste0("data/processed/build-data-products/blank_filtered_evaluated_qc_", file_name, ".parquet")
    )
}

blank_filtered_analyte_concentration_quality_control_no_recovery <- arrow::read_parquet(
  "data/processed/build-data-products/blank_filtered_analyte_concentration_quality_control_no_recovery.parquet"
)
blank_filtered_analyte_concentration_quality_control_with_recovery <- arrow::read_parquet(
  "data/processed/build-data-products/blank_filtered_analyte_concentration_quality_control_with_recovery.parquet"
)

native_analyte_quality_control_levels <- arrow::read_parquet(
  "data/processed/reference/native_analyte_quality_control_levels.parquet"
)


eval_qc_for_blank_filtered_analyte(
  blank_filtered_analyte_concentration_quality_control_no_recovery,
  native_analyte_quality_control_levels,
  "no_recovery"
)

eval_qc_for_blank_filtered_analyte(
  blank_filtered_analyte_concentration_quality_control_with_recovery,
  native_analyte_quality_control_levels,
  "with_recovery"
)
