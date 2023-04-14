library(magrittr)

# Check Source Internal Standard to Native Analyte Matching ----

native_analyte_internal_standard_mapping_df <- arrow::read_parquet("data/processed/reference/native_analyte_internal_standard_mapping.parquet")

individual_native_analyte_df <- arrow::read_parquet("data/processed/source/source_data_individual_native_analyte.parquet") %>%
  dplyr::select(
    individual_native_analyte_name,
    source_file_name,
    filename,
    replicate_number,
    calibration_level,
    individual_native_analyte_peak_area
  ) %>%
  # remove duplicates
  dplyr::distinct_all() %>%
  # ranking to find the highest value of peak area
  dplyr::group_by(
    individual_native_analyte_name,
    source_file_name,
    filename,
    replicate_number,
    calibration_level
  ) %>%
  dplyr::mutate(
    calibration_rank = dplyr::row_number(dplyr::desc(individual_native_analyte_peak_area))
  ) %>%
  dplyr::ungroup() %>%
  dplyr::filter(calibration_rank == 1) %>%
  dplyr::select(
    individual_native_analyte_name,
    source_file_name,
    filename,
    replicate_number,
    calibration_level,
    individual_native_analyte_peak_area
  )


internal_standard_df <- arrow::read_parquet("data/processed/source/source_data_internal_standard.parquet") %>%
  dplyr::select(
    internal_standard_name,
    source_file_name,
    filename,
    internal_standard_peak_area
  ) %>%
  dplyr::distinct_all() %>%
  dplyr::group_by(
    internal_standard_name,
    source_file_name,
    filename
  ) %>%
  # identify instance with largest internal peak area
  dplyr::mutate(
    calibration_rank = dplyr::row_number(dplyr::desc(internal_standard_peak_area))
  ) %>%
  dplyr::ungroup() %>%
  # filter down to the highest peak area for a given internal standard + filename
  dplyr::filter(calibration_rank == 1) %>%
  dplyr::select(
    internal_standard_name,
    source_file_name,
    filename,
    internal_standard_peak_area
  )

check_df <- individual_native_analyte_df %>%
  dplyr::left_join(native_analyte_internal_standard_mapping_df, by = "individual_native_analyte_name") %>%
  dplyr::left_join(internal_standard_df, by = c("internal_standard_name", "source_file_name", "filename")) %>%
  dplyr::filter(is.na(internal_standard_peak_area))

# no issues found

# Check Analyte Concentration To Source ----
# Looking for instances where there is not a matching analyte concentration
# to a given source analyte value


# processed from Sep2021Calibration_Curve_source.xlsx
analyte_concentration_df <- arrow::read_parquet(
  "data/processed/native_analyte_concentration.parquet"
)

# native analyte name mapping between source
# and Sep2021Calibration_Curve_source.xlsx
cal_name_native_analyte_mapping_df <- arrow::read_parquet(
  "data/processed/mapping/analyte_concentration_name_mapping.parquet"
) %>%
  dplyr::rename(mapped_analyte_name = individual_native_analyte_name)

average_peak_ratio <- arrow::read_parquet(
  "data/processed/calibration-curve/average_peak_area_ratio.parquet"
)

processed_analyte_concentration <- analyte_concentration_df %>%
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
  dplyr::mutate(
    calibration_level = readr::parse_number(calibration_level)
  ) %>%
  dplyr::select(
    individual_native_analyte_name,
    calibration_level,
    native_analyte_concentration_ppt
  )

average_peak_ratio %>%
  dplyr::left_join(
    processed_analyte_concentration,
    by = c("individual_native_analyte_name", "calibration_level")
  ) %>%
  dplyr::filter(is.na(native_analyte_concentration_ppt)) %>%
  dplyr::distinct(
    individual_native_analyte_name,
    internal_standard_name
  ) %>%
  as.data.frame() %>%
  xlsx::write.xlsx(
    "data/processed/troubleshoot/matching-issue/missing_source_analyte_name_from_concentration.xlsx",
    row.names = FALSE
  )

# Check Internal Standard Source to Concentration Mapping  ----
# Looking for instances where there is not a valid mapped internal standard
# name between the average analyte file and the concentration file

# processed from Sep2021Calibration_Curve_source.xlsx
internal_standard_concen_df <- arrow::read_parquet(
  "data/processed/internal_standard_concentration.parquet"
) %>%
  dplyr::rename(
    concentration_internal_standard_name = internal_standard_name
  )

internal_standard_name_mapping <- arrow::read_parquet(
  "data/processed/reference/concentration_internal_standard_mapping.parquet"
)

adjusted_int_st_concen <- internal_standard_concen_df %>%
  dplyr::left_join(
    internal_standard_name_mapping,
    by = c("concentration_internal_standard_name")
  ) %>%
  dplyr::mutate(
    internal_standard_name = ifelse(is.na(mapped_internal_standard_name),
      concentration_internal_standard_name,
      mapped_internal_standard_name
    )
  ) %>%
  dplyr::mutate(
    calibration_level = readr::parse_number(calibration_level)
  ) %>%
  dplyr::distinct(
    internal_standard_name,
    calibration_level,
    internal_standard_concentration_ppt
  )

source_data_int_st <- arrow::read_parquet(
  "data/processed/source/source_data_internal_standard.parquet"
) %>%
  dplyr::distinct(
    internal_standard_name,
    calibration_level
  )

source_data_int_st %>%
  dplyr::left_join(
    adjusted_int_st_concen,
    by = c("internal_standard_name", "calibration_level")
  ) %>%
  dplyr::filter(
    is.na(internal_standard_concentration_ppt)
  ) %>%
  dplyr::distinct(
    internal_standard_name
  ) %>%
  as.data.frame() %>%
  xlsx::write.xlsx(
    "data/processed/troubleshoot/matching-issue/internal-standard-source-to-concentration-mapping-issue.xlsx",
    row.names = FALSE
  )
