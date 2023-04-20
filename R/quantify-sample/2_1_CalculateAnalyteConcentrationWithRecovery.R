#' Build the Analyte Concentration Table
#'
#' Input:
#'   Data:
#'
#'

source("R/process-source-data/ProcessExtractionBatchSource.R")
source("R/quantify-sample/1_BuildSamplePeakAreaRatio.R")

library(magrittr)

peak_area_ratio <- arrow::read_parquet(
  "data/processed/quantify-sample/peak_area_ratio.parquet"
)

calibration_curve_output <- arrow::read_parquet(
  "data/processed/calibration-curve/calibration_curve_output.parquet"
) %>%
  # doing a distinct since the calibration curve output file includes values
  # not relevant to the calculation of the analyte concentration
  dplyr::distinct(
    batch_number,
    individual_native_analyte_name,
    slope,
    y_intercept,
    r_squared,
    calibration_point,
    calibration_range,
    minimum_average_peak_area_ratio,
    maximum_average_peak_area_ratio
  )

extraction_batch_source <- arrow::read_parquet(
  "data/processed/reference/extraction_batch_source.parquet"
) %>%
  dplyr::select(
    batch_number,
    cartridge_number,
    internal_standard_used
  )

internal_standard_mix <- arrow::read_parquet(
  "data/processed/reference/internal_standard_mix.parquet"
) %>%
  dplyr::select(
    internal_standard_used = internal_standard_mix,
    internal_standard_name = internal_standard_concentration_name,
    stock_mix,
    internal_standard_concentration_ppb
  )

concen_internal_stanard_mapping <- arrow::read_parquet(
  "data/processed/mapping/concentration_internal_standard_mapping.parquet"
)


peak_area_ratio %>%
  dplyr::left_join(
    calibration_curve_output,
    by = c("batch_number", "individual_native_analyte_name")
  ) %>%
  dplyr::left_join(
    extraction_batch_source,
    by = c("batch_number", "cartridge_number")
  ) %>%
  dplyr::rename(
    source_internal_standard_name = internal_standard_name
  ) %>%
  dplyr::left_join(
    concen_internal_stanard_mapping,
    by = c("source_internal_standard_name" = "mapped_internal_standard_name")
  ) %>%
  dplyr::mutate(
    internal_standard_name = ifelse(is.na(concentration_internal_standard_name),
      source_internal_standard_name,
      concentration_internal_standard_name
    )
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
    analyte_concentration_ng = ((peak_area_ratio - y_intercept) / slope) * internal_standard_concentration_ng
  ) %>%
  dplyr::group_by(
    batch_number,
    individual_native_analyte_name
  ) %>%
  dplyr::mutate(
    calibration_curve_range_category = dplyr::case_when(
      peak_area_ratio < minimum_average_peak_area_ratio ~ "Below Calibration Range",
      minimum_average_peak_area_ratio < peak_area_ratio & peak_area_ratio < maximum_average_peak_area_ratio ~ "Within Calibration Range",
      peak_area_ratio > maximum_average_peak_area_ratio ~ "Above Calibration Range"
    )
  ) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(
    analyte_concentration = dplyr::if_else(
      calibration_curve_range_category == "Below Calibration Range",
      NaN,
      analyte_concentration_ng
    )
  ) %>%
  dplyr::select(
    batch_number,
    cartridge_number,
    individual_native_analyte_name,
    analyte_detection_flag,
    individual_native_analyte_peak_area,
    internal_standard_name,
    internal_standard_detection_flag,
    internal_standard_peak_area,
    peak_area_ratio,
    minimum_average_peak_area_ratio,
    maximum_average_peak_area_ratio,
    calibration_curve_range_category,
    slope,
    y_intercept,
    r_squared,
    calibration_point,
    calibration_range,
    internal_standard_used,
    stock_mix,
    internal_standard_concentration_ppb,
    internal_standard_concentration_ng,
    analyte_concentration_ng
  ) %>%
  arrow::write_parquet(
    sink = "data/processed/quantify-sample/analyte_concentration_with_recovery.parquet"
  ) %>%
  readr::write_excel_csv(
    "data/processed/quantify-sample/analyte_concentration_with_recovery.csv"
  )
