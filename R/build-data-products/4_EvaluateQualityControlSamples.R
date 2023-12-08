library(magrittr)

source("R/build-data-products/3_2_RemoveFieldBlanksFromBlankFilteredAnalyte.R")
source("R/process-source-data/ProcessQCSampleFile.R")

eval_qc_for_blank_filtered_analyte <- function(blank_filtered_analyte_concentration_quality_control,
                                               native_analyte_quality_control_levels,
                                               file_name) {
  df <- blank_filtered_analyte_concentration_quality_control %>%
    dplyr::left_join(
      native_analyte_quality_control_levels,
      by = c("individual_native_analyte_name", "quality_control_level")
    ) %>%
    dplyr::mutate(
      quality_control_recovery_ratio = (average_qc_analyte_concentration_ng / native_analyte_spiked_in_qc_samples_ng) * 100,
      evaluate_recovery_ratio_flag = ifelse(quality_control_recovery_ratio > 70.0 & quality_control_recovery_ratio < 130.0, "PASS", "FAIL")
    ) %>%
    dplyr::select(
      batch_number,
      individual_native_analyte_name,
      quality_control_exists_flag,
      quality_control_level,
      quality_control_adjust_flag,
      average_qc_analyte_concentration_ng,
      native_analyte_spiked_in_qc_samples_ng,
      percent_rsd_qc_analyte_concentration_ng,
      quality_control_recovery_ratio,
      evaluate_recovery_ratio_flag
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
