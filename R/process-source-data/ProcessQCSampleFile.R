native_analyte_quality_control_levels <- readxl::read_excel(
  "data/source/reference/native_analyte_quality_control_levels.xlsx",
  .name_repair = "unique_quiet"
) %>%
  dplyr::select(
    source_analyte_name = native_analyte_name,
    QC_mix,
    native_analyte_spiked_in_qc_samples_ng = native_analyte_spiked_in_QCsamples_ng
  )

analyte_concentration_name_mapping <- arrow::read_parquet(
  "data/processed/mapping/analyte_concentration_name_mapping.parquet"
)

native_analyte_quality_control_levels %>%
  dplyr::mutate(
    quality_control_level = stringr::str_sub(QC_mix, 1, 1)
  ) %>%
  # logic to combine Linear and Branched PFOS into "∑ PFOS"
  dplyr::mutate(
    source_analyte_name = dplyr::if_else(
      (source_analyte_name == "Linear PFOS" | source_analyte_name == "Branched PFOS"),
      "∑ PFOS",
      source_analyte_name
    )
  ) %>%
  dplyr::group_by(
    source_analyte_name,
    quality_control_level
  ) %>%
  dplyr::summarise(
    native_analyte_spiked_in_qc_samples_ng = sum(native_analyte_spiked_in_qc_samples_ng),
    .groups = "keep"
  ) %>%
  dplyr::ungroup() %>%
  dplyr::left_join(
    analyte_concentration_name_mapping,
    by = "source_analyte_name"
  ) %>%
  dplyr::mutate(
    individual_native_analyte_name = dplyr::if_else(
      is.na(individual_native_analyte_name),
      source_analyte_name,
      individual_native_analyte_name
    )
  ) %>%
  dplyr::select(
    individual_native_analyte_name,
    quality_control_level,
    native_analyte_spiked_in_qc_samples_ng
  ) %>%
  readr::write_excel_csv(
    "data/processed/reference/native_analyte_quality_control_levels.csv"
  ) %>%
  arrow::write_parquet(
    sink = "data/processed/reference/native_analyte_quality_control_levels.parquet"
  )
