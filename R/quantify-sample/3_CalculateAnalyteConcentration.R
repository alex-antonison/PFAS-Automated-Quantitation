#' Build the Analyte Concentration Table
#'
#' Input:
#'   Data:
#'
#'

source("R/quantify-sample/2_BuildLimitOfDetectionReference.R")

library(magrittr)

peak_area_ratio <- arrow::read_parquet(
  "data/processed/quantify-sample/peak_area_ratio.parquet"
)

calibration_curve_output_no_recovery <- arrow::read_parquet(
  "data/processed/calibration-curve/calibration_curve_output_no_recov_filter.parquet"
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

calibration_curve_output_with_recovery <- arrow::read_parquet(
  "data/processed/calibration-curve/calibration_curve_output_with_recov.parquet"
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

lod_with_recovery <- arrow::read_parquet(
  "data/processed/quantify-sample/analyte_limit_of_detection_reference_with_recovery.parquet"
)

lod_no_recovery <- arrow::read_parquet(
  "data/processed/quantify-sample/analyte_limit_of_detection_reference_no_recovery.parquet"
)


calculate_analyte_concentration <- function(peak_area_ratio,
                                            calibration_curve_output,
                                            extraction_batch_source,
                                            internal_standard_mix,
                                            concen_internal_stanard_mapping,
                                            lod_reference,
                                            output_base_name) {
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
    dplyr::left_join(
      lod_reference,
      by = c("batch_number", "individual_native_analyte_name")
    ) %>% 
    dplyr::mutate(
      lod_exist_flag = dplyr::if_else(
        is.na(limit_of_detection_concentration_ng),
        FALSE,
        TRUE
      )
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
        peak_area_ratio < limit_of_detection_concentration_ng ~ "<LOD",
        peak_area_ratio < minimum_average_peak_area_ratio ~ "<LOQ",
        minimum_average_peak_area_ratio < peak_area_ratio & peak_area_ratio < maximum_average_peak_area_ratio ~ "Within Calibration Range",
        peak_area_ratio > maximum_average_peak_area_ratio ~ "Above Calibration Range"
      )
    ) %>%
    dplyr::ungroup() %>%
    dplyr::select(
      batch_number,
      cartridge_number,
      individual_native_analyte_name,
      analyte_detection_flag,
      lod_exist_flag,
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
      limit_of_detection_concentration_ng,
      analyte_concentration_ng
    ) %>%
    arrow::write_parquet(
      sink = paste0("data/processed/quantify-sample/", output_base_name, ".parquet")
    ) %>%
    readr::write_excel_csv(
      paste0("data/processed/quantify-sample/", output_base_name, ".csv")
    )
}

calculate_analyte_concentration(peak_area_ratio,
  calibration_curve_output_with_recovery,
  extraction_batch_source,
  internal_standard_mix,
  concen_internal_stanard_mapping,
  lod_with_recovery,
  output_base_name = "analyte_concentration_with_recovery"
)

calculate_analyte_concentration(peak_area_ratio,
  calibration_curve_output_no_recovery,
  extraction_batch_source,
  internal_standard_mix,
  concen_internal_stanard_mapping,
  lod_no_recovery,
  output_base_name = "analyte_concentration_no_recovery"
)
