library(magrittr)

extraction_batch_source <- arrow::read_parquet(
  "data/processed/extraction_batch_source.parquet"
)

analyte_concentration_df <- arrow::read_parquet(
  "data/processed/quantify-sample/analyte_concentration.parquet"
)

analyte_peak_area <- analyte_concentration_df %>%
  # dplyr::filter(source_type == "native_analyte") %>%
  # dplyr::filter(analyte_match == "Match Found") %>%
  # remove MeOH
  # dplyr::filter(!stringr::str_detect(filename, "MeOH")) %>%
  # # remove Calibration filename
  # dplyr::filter(!stringr::str_detect(filename, "Cal")) %>%
  # dplyr::mutate(
  #   # rename to cartridge_number for joining later
  #   cartridge_number = filename,
  #   # convert peak area to numeric
  #   area_with_nan = dplyr::na_if(area, "NF"),
#   individual_native_analyte_peak_area = as.numeric(area_with_nan),
#   # calculate analyte name
#   analyte_name_length = stringr::str_length(sheet_name),
#   individual_native_analyte_name = stringr::str_sub(sheet_name, 0, analyte_name_length - 2),
#   # calculate transition number
#   transition_number = stringr::str_sub(sheet_name, -1)
# ) %>%
# dplyr::filter(transition_number == 1) %>%
dplyr::select(
  batch_number,
  individual_native_analyte_name,
  cartridge_number,
  calibration_curve_range_category,
  analyte_concentration_ng = analyte_concentration
)


cur_df <- analyte_peak_area %>%
  dplyr::filter(batch_number == 2) %>% 
  dplyr::left_join(
    extraction_batch_source,
    by = c("batch_number", "cartridge_number")
  ) %>%
  # filter down to blanks and QC
  dplyr::filter(stringr::str_detect(county, "Extraction Blank")) %>%
  # instances where NF, set to 0
  # dplyr::mutate(
  #   individual_native_analyte_peak_area = dplyr::if_else(
  #     is.na(individual_native_analyte_peak_area),
  #     0,
  #     individual_native_analyte_peak_area
  #   )
  # ) %>%
  dplyr::select(
    batch_number,
    cartridge_number,
    individual_native_analyte_name,
    county,
    sample_id,
    sample_mass_g,
    analyte_concentration_ng
  ) #%>% 
# dplyr::group_by(
#   batch_number,
#   individual_native_analyte_name
#   ) %>% 
# dplyr::summarise(
#   average_analyte_concentration_ng = mean(analyte_concentration_ng)
# )
