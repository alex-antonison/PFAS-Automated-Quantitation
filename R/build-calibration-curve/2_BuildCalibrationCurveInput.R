#' Build the Calibration Curve Input Table
#'
#' Combines the Average Peak Area Ratio output to the
#' Concentration Ratio Output
#'
#' Input:
#'   Data:
#'     - data/processed/calibration-curve/average_peak_area_ratio.parquet
#'     - data/processed/calibration-curve/concentration_ratio.parquet
#'
#' Output:
#'   - data/processed/calibration-curve/calibration_curve_input.parquet

library(magrittr)

source("R/build-calibration-curve/1_CalculateAveragePeakRatio.R")
source("R/build-calibration-curve/1_CalculateConcentrationRatio.R")

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
  arrow::write_parquet(
    sink = "data/processed/calibration-curve/calibration_curve_input.parquet"
  ) %>%
  as.data.frame() %>%
  xlsx::write.xlsx(
    "data/processed/calibration-curve/calibration_curve_input.xlsx",
    row.names = FALSE
  )
