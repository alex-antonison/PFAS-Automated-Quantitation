library(magrittr)

extraction_batch_source <- arrow::read_parquet(
  "data/processed/reference/extraction_batch_source.parquet"
)

analyte_concentration_df <- arrow::read_parquet(
  "data/processed/quantify-sample/analyte_concentration_no_recovery.parquet"
)

qc_filtered_samples <- analyte_concentration_df %>%
  dplyr::inner_join(
    extraction_batch_source,
    by = c("batch_number", "cartridge_number")
  ) %>%
  dplyr::filter(stringr::str_detect(county, "QC")) %>%
  dplyr::filter(batch_number == 2) %>%
  dplyr::filter(individual_native_analyte_name == "PFBA") %>%
  dplyr::mutate(
    sample_name_length = stringr::str_length(sample_id),
    qc_replicate = stringr::str_sub(
      sample_id,
      sample_name_length,
      sample_name_length
    ),
    qc_level = stringr::str_sub(
      sample_id,
      sample_name_length - 1,
      sample_name_length - 1
    )
  ) %>%
  dplyr::select(
    batch_number,
    individual_native_analyte_name,
    cartridge_number,
    # calibration_curve_range_category,
    county,
    sample_id,
    qc_level,
    qc_replicate,
    analyte_concentration_ng
  )

# Average together Batch + Analyte + QC Level -> average_analyte_concentration_ng

qc_filtered_samples %>%
  dplyr::group_by(
    batch_number,
    individual_native_analyte_name,
    qc_level
  ) %>%
  dplyr::summarise(
    average_qc_analyte_concentration_ng = mean(analyte_concentration_ng)
  )
