library(magrittr)

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

eval_df <- average_peak_area_ratio %>%
  dplyr::left_join(
    analyte_limit_of_detection_reference,
    by = "individual_native_analyte_name"
  ) %>%
  dplyr::mutate(
    check_for_config = dplyr::if_else(
      is.na(cal_level_lod),
      "Missing LoD Level",
      "LoD Level Exists"
    ),
    cal_lod_level_exists = dplyr::if_else(
      calibration_level == cal_level_lod,
      TRUE,
      FALSE
    )
  ) %>%
  dplyr::filter(cal_lod_level_exists) %>%
  dplyr::distinct(
    batch_number,
    individual_native_analyte_name,
    cal_level_exists_for_lod_flag = "Cal Level Exists"
  )

average_peak_area_ratio %>%
  dplyr::distinct(
    batch_number,
    individual_native_analyte_name
  ) %>%
  dplyr::left_join(
    eval_df,
    by = c("batch_number", "individual_native_analyte_name")
  ) %>%
  dplyr::mutate(
    cal_level_exists_for_lod_flag = dplyr::if_else(
      is.na(cal_level_exists_for_lod_flag),
      "Cal Level Missing for LoD Config",
      cal_level_exists_for_lod_flag
    )
  ) %>%
  readr::write_excel_csv(
    "data/processed/troubleshoot/cal_level_versus_lod_cal_level.csv"
  )
