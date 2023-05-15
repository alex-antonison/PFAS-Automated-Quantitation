library(magrittr)

source("R/process-source-data/ProcessExtractionBatchSource.R")
source("R/quantify-sample/1_BuildSamplePeakAreaRatio.R")

calibration_curve_output_no_recovery <- arrow::read_parquet(
  "data/processed/calibration-curve/calibration_curve_output_no_recov_filter.parquet"
) %>%
  dplyr::distinct(
    batch_number,
    individual_native_analyte_name,
    y_intercept,
    slope
  )

calibration_curve_output_with_recovery <- arrow::read_parquet(
  "data/processed/calibration-curve/calibration_curve_output_with_recov.parquet"
) %>%
  dplyr::distinct(
    batch_number,
    individual_native_analyte_name,
    y_intercept,
    slope
  )

analyte_limit_of_detection_reference <- arrow::read_parquet(
  "data/processed/mapping/native_analyte_internal_standard_mapping.parquet"
) %>%
  dplyr::select(
    individual_native_analyte_name,
    cal_level_lod
  )

average_peak_area_ratio <- arrow::read_parquet(
  "data/processed/calibration-curve/average_peak_area_ratio.parquet"
) %>%
  dplyr::select(
    batch_number,
    individual_native_analyte_name,
    calibration_level,
    average_peak_area_ratio
  )

process_limit_of_detection_file <- function(average_peak_area_ratio,
                                            analyte_limit_of_detection_reference,
                                            calibration_curve_output,
                                            file_name_base) {
  average_peak_area_ratio %>%
    dplyr::left_join(
      analyte_limit_of_detection_reference,
      by = "individual_native_analyte_name"
    ) %>%
    dplyr::left_join(
      calibration_curve_output,
      by = c("batch_number", "individual_native_analyte_name")
    ) %>%
    dplyr::filter(
      calibration_level == cal_level_lod
    ) %>%
    dplyr::mutate(
      limit_of_detection_area_ratio = average_peak_area_ratio
    ) %>%
    dplyr::mutate(
      limit_of_detection_concentration_ng = (limit_of_detection_area_ratio - y_intercept) / slope
    ) %>%
    dplyr::select(
      batch_number,
      individual_native_analyte_name,
      limit_of_detection_area_ratio,
      limit_of_detection_concentration_ng
    ) %>% 
    arrow::write_parquet(
      sink = paste0(
        "data/processed/quantify-sample/analyte_limit_of_detection_reference",
        file_name_base,
        ".parquet"
      )
    ) %>%
    readr::write_csv(
      paste0(
        "data/processed/quantify-sample/analyte_limit_of_detection_reference",
        file_name_base,
        ".csv"
      )
    )
}

process_limit_of_detection_file(average_peak_area_ratio,
                                analyte_limit_of_detection_reference,
                                calibration_curve_output_with_recovery,
                                "_with_recovery")

process_limit_of_detection_file(average_peak_area_ratio,
                                analyte_limit_of_detection_reference,
                                calibration_curve_output_with_recovery,
                                "_no_recovery")