#' Build the Analyte Concentration Table
#'
#' Input:
#'   Data:
#'
#'

source("R/quantify-sample/BuildSamplePeakAreaRatio.R")
source("R/build-calibration-curve/CalculateCalibrationCurve.R")
source("R/process-source-data/ProcessExtractionBatchSource.R")

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

peak_area_ratio %>%
  dplyr::left_join(
    calibration_curve_output,
    by = "individual_native_analyte_name"
  ) %>%
  dplyr::left_join(
    extraction_batch_source,
    by = c("batch_number", "cartridge_number")
  ) %>%
  dplyr::left_join(
    internal_standard_mix,
    by = c("internal_standard_name", "internal_standard_used")
  ) %>%
  # calculate amount of internal standard in each sample
  dplyr::mutate(
    # TODO make the value 25 a configurable number
    internal_standard_concentration_ng = ((internal_standard_concentration_ppb * 1000) / 1000000) * 25
  ) %>%
  # calculate Analyte Concentration
  dplyr::mutate(
    analyte_concentration = ((peak_area_ratio - y_intercept) / slope) * internal_standard_concentration_ng
  ) %>%
  arrow::write_parquet(
    sink = "data/processed/quantify-sample/analyte_concentration.parquet"
  ) %>%
  readr::write_excel_csv(
    "data/processed/quantify-sample/analyte_concentration.csv"
  )
