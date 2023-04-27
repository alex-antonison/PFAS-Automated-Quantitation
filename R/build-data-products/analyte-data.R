

df = arrow::read_parquet(
  "data/processed/quantify-sample/analyte_concentration_with_recovery.parquet"
)

source_data <- arrow::read_parquet(
  "data/processed/source/full_raw_data.parquet"
) %>% 
  dplyr::select(
    filename,
    batch_number,
    sheet_name,
    source_file_name
  ) %>% 
  dplyr::filter(
    batch_number == 2
  ) %>% 
  dplyr::mutate(
    analyte_name_length = stringr::str_length(sheet_name),
    # remove the _# from the end of the analyte name
    individual_native_analyte_name = stringr::str_sub(sheet_name, 0, analyte_name_length - 2),
    transition_number = stringr::str_sub(sheet_name, -1),
    cartridge_number = filename
  ) %>% 
  dplyr::filter(transition_number == 1)




eval_df <- df %>% 
  dplyr::filter(analyte_concentration_ng < 0) %>% 
  dplyr::filter(batch_number == 2) %>% 
  # dplyr::filter(individual_native_analyte_name == "4_2FTS") %>% 
  dplyr::select(
    batch_number,
    individual_native_analyte_name,
    individual_native_analyte_peak_area,
    calibration_curve_range_category,
    cartridge_number,
    calibration_point,
    analyte_concentration_ng
  )
  # dplyr::left_join(
  #   source_data,
  #   by = c("batch_number", "cartridge_number", "individual_native_analyte_name")
  # )


eval_df <- df %>% 
  dplyr::filter(analyte_concentration_ng < 0) %>% 
  dplyr::filter(batch_number == 2) %>%
  dplyr::select(
    batch_number,
    individual_native_analyte_name,
    calibration_point
  )
