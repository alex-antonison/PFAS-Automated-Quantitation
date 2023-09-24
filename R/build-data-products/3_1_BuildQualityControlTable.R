library(magrittr)

source("R/build-data-products/2_RemoveExtractionBlankFromAnalyteConcentration.R")

build_qc_table <- function(extraction_batch_source,
                           blank_filtered_analyte_concentration_df,
                           quality_control_blank_filter_adjustment,
                           file_name) {
  qc_filtered_samples <- blank_filtered_analyte_concentration_df %>%
    dplyr::inner_join(
      extraction_batch_source,
      by = c("batch_number", "cartridge_number")
    ) %>%
    # filter to just QC Samples
    dplyr::filter(
      county == "Fresh Water QC" | county == "Salt Water QC"
    ) %>%
    # pull out qc level and replicate
    dplyr::mutate(
      quality_control_sample_type = county,
      sample_name_length = stringr::str_length(sample_id),
      quality_control_replicate = stringr::str_sub(
        sample_id,
        sample_name_length,
        sample_name_length
      ),
      quality_control_level = stringr::str_sub(
        sample_id,
        sample_name_length - 1,
        sample_name_length - 1
      ),
      replicate_missing_flag = dplyr::if_else(
        is.na(analyte_concentration_ng),
        TRUE,
        FALSE
      )
    ) %>%
    # subtract blank filtered values
    dplyr::left_join(
      quality_control_sample_adjustment,
      by = c("individual_native_analyte_name", "quality_control_sample_type")
    ) %>%
    dplyr::mutate(
      quality_control_adjust_flag = ifelse(!is.na(ng_to_filter_ng), TRUE, FALSE),
      ng_to_filter_ng_na_fix = ifelse(is.na(ng_to_filter_ng), 0.0, ng_to_filter_ng),
      adjusted_analyte_concentration_ng = blank_filtered_analyte_concentration_ng - ng_to_filter_ng_na_fix
    ) %>%
    dplyr::select(
      batch_number,
      individual_native_analyte_name,
      cartridge_number,
      quality_control_adjust_flag,
      sample_id,
      quality_control_level,
      quality_control_replicate,
      replicate_missing_flag,
      blank_filtered_analyte_concentration_ng,
      ng_to_filter_ng_na_fix,
      adjusted_analyte_concentration_ng
    )


  # Account for missing replicate in QC samples

  qc_missing_replicate_levels <- qc_filtered_samples %>%
    dplyr::filter(replicate_missing_flag) %>%
    dplyr::distinct(
      batch_number,
      individual_native_analyte_name,
      quality_control_level,
      keep_qc_entry = FALSE
    )

  # Average together Batch + Analyte + QC Level -> average_analyte_concentration_ng
  average_qc_analyte_concentration <- qc_filtered_samples %>%
    dplyr::left_join(
      qc_missing_replicate_levels,
      by = c(
        "batch_number",
        "individual_native_analyte_name",
        "quality_control_level"
      )
    ) %>%
    # if an analyte qc level does not exist in the remove table,
    # set remove to false
    dplyr::mutate(
      keep_qc_entry = dplyr::if_else(
        is.na(keep_qc_entry),
        TRUE,
        FALSE
      )
    ) %>%
    # this will remove all of the analyte qc levels that are missing
    # one of the replicates
    dplyr::filter(keep_qc_entry) %>%
    # calculate the average qc
    dplyr::group_by(
      batch_number,
      quality_control_adjust_flag,
      individual_native_analyte_name,
      quality_control_level
    ) %>%
    dplyr::summarise(
      average_qc_analyte_concentration_ng = mean(adjusted_analyte_concentration_ng),
      std_dev_qc_analyte_concentration_ng = sd(adjusted_analyte_concentration_ng),
      percent_rsd_qc_analyte_concentration_ng = (std_dev_qc_analyte_concentration_ng / average_qc_analyte_concentration_ng) * 100
    ) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(
      quality_control_exists_flag = TRUE
    ) %>%
    dplyr::select(
      batch_number,
      individual_native_analyte_name,
      quality_control_level,
      quality_control_exists_flag,
      quality_control_adjust_flag,
      average_qc_analyte_concentration_ng,
      std_dev_qc_analyte_concentration_ng,
      percent_rsd_qc_analyte_concentration_ng
    )

  qc_missing_replicate_levels <- qc_missing_replicate_levels %>%
    dplyr::mutate(
      quality_control_adjust_flag = FALSE,
      quality_control_exists_flag = FALSE,
      average_qc_analyte_concentration_ng = NA,
      std_dev_qc_analyte_concentration_ng = NA,
      percent_rsd_qc_analyte_concentration_ng = NA
    ) %>%
    dplyr::select(
      batch_number,
      individual_native_analyte_name,
      quality_control_level,
      quality_control_exists_flag,
      quality_control_adjust_flag,
      average_qc_analyte_concentration_ng,
      std_dev_qc_analyte_concentration_ng,
      percent_rsd_qc_analyte_concentration_ng
    )

  combined_qc_levels <- dplyr::bind_rows(
    qc_missing_replicate_levels,
    average_qc_analyte_concentration
  )

  combined_qc_levels %>%
    readr::write_excel_csv(
      paste0(
        "data/processed/build-data-products/blank_filtered_analyte_concentration_quality_control_",
        file_name,
        ".csv"
      )
    ) %>%
    arrow::write_parquet(
      paste0(
        "data/processed/build-data-products/blank_filtered_analyte_concentration_quality_control_",
        file_name,
        ".parquet"
      )
    )
}

extraction_batch_source <- arrow::read_parquet(
  "data/processed/reference/extraction_batch_source.parquet"
)

quality_control_sample_adjustment <- arrow::read_parquet(
  "data/processed/reference/quality_control_blank_filter_adjustment.parquet"
)

blank_filtered_analyte_concentration_with_recovery <- arrow::read_parquet(
  "data/processed/build-data-products/blank_filtered_analyte_concentration_with_recovery.parquet"
)

blank_filtered_analyte_concentration_no_recovery <- arrow::read_parquet(
  "data/processed/build-data-products/blank_filtered_analyte_concentration_no_recovery.parquet"
)

build_qc_table(
  extraction_batch_source,
  blank_filtered_analyte_concentration_with_recovery,
  quality_control_sample_adjustment,
  "with_recovery"
)

build_qc_table(
  extraction_batch_source,
  blank_filtered_analyte_concentration_no_recovery,
  quality_control_sample_adjustment,
  "no_recovery"
)
