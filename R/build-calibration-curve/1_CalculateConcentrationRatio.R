#' Calculate the Concentration Ratio
#'
#' Input:
#'   - Sep2021Calibration_Curve_source.xlsx
#'   - Reference mapping between Native Analyte and Internal Standard
#'   - Reference mapping between Native Analyte names in source data and calibration curve


library(magrittr)

# processed from Sep2021Calibration_Curve_source.xlsx
analyte_concentration_df <- arrow::read_parquet(
  "data/processed/reference/native_analyte_concentration.parquet"
)

# processed from Sep2021Calibration_Curve_source.xlsx
internal_standard_concen_df <- arrow::read_parquet(
  "data/processed/reference/internal_standard_concentration.parquet"
)

# native analyte to internal standard mapping
native_analyte_internal_standard_mapping_df <- arrow::read_parquet(
  "data/processed/mapping/native_analyte_internal_standard_mapping.parquet"
)

# native analyte name mapping between source
# and Sep2021Calibration_Curve_source.xlsx
cal_name_native_analyte_mapping_df <- arrow::read_parquet(
  "data/processed/mapping/analyte_concentration_name_mapping.parquet"
) %>%
  dplyr::rename(mapped_analyte_name = individual_native_analyte_name)

concen_internal_standard_mapping <- arrow::read_parquet(
  "data/processed/mapping/concentration_internal_standard_mapping.parquet"
)

analyte_concentration_df %>%
  dplyr::rename(source_analyte_name = individual_native_analyte_name) %>%
  dplyr::left_join(
    cal_name_native_analyte_mapping_df,
    by = "source_analyte_name"
  ) %>%
  dplyr::mutate(
    individual_native_analyte_name = ifelse(is.na(mapped_analyte_name),
      source_analyte_name,
      mapped_analyte_name
    )
  ) %>%
  dplyr::left_join(
    native_analyte_internal_standard_mapping_df,
    by = c("individual_native_analyte_name")
  ) %>%
  dplyr::rename(
    source_internal_standard_name = internal_standard_name
  ) %>%
  dplyr::left_join(
    concen_internal_standard_mapping,
    by = c("source_internal_standard_name" = "mapped_internal_standard_name")
  ) %>%
  dplyr::mutate(
    internal_standard_name = ifelse(is.na(concentration_internal_standard_name),
      source_internal_standard_name,
      concentration_internal_standard_name
    )
  ) %>%
  dplyr::left_join(
    internal_standard_concen_df,
    by = c("internal_standard_name", "calibration_mix", "calibration_level")
  ) %>%
  dplyr::mutate(
    analyte_concentration_ratio = native_analyte_concentration_ppt / internal_standard_concentration_ppt # nolint
  ) %>%
  dplyr::select(
    individual_native_analyte_name,
    internal_standard_name,
    calibration_level,
    analyte_concentration_ratio
  ) %>%
  dplyr::mutate(
    calibration_level = readr::parse_number(calibration_level)
  ) %>%
  arrow::write_parquet(
    sink = "data/processed/calibration-curve/concentration_ratio.parquet"
  ) %>%
  readr::write_csv(
    "data/processed/calibration-curve/concentration_ratio.csv"
  )
