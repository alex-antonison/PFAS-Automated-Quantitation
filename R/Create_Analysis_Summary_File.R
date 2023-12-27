## Need to restart R Session prior to running this script

library(magrittr)
options(java.parameters = "-Xmx30720m")

# set up initial workbook
wb <- xlsx::createWorkbook()


########## Sheet 1 - Build a quality control pass fail across batches ##########
print("Creating Pass Fail Summary")

quality_control_pass_fail_df <- arrow::read_parquet("data/processed/build-data-products/blank_filtered_evaluated_qc_no_recovery.parquet") %>%
  dplyr::select(-quality_control_exists_flag, -quality_control_adjust_flag) %>%
  dplyr::filter(!is.na(evaluate_recovery_ratio_flag)) %>%
  dplyr::group_by(batch_number, evaluate_recovery_ratio_flag) %>%
  dplyr::summarise(count = dplyr::n(), .groups = "keep") %>%
  dplyr::arrange(batch_number) %>%
  data.frame()

quality_control_pass_fail_sheet <- xlsx::createSheet(wb, "Pass Fail Summary")
xlsx::addDataFrame(quality_control_pass_fail_df, sheet = quality_control_pass_fail_sheet, row.names = FALSE)


########## Sheet 2 -  Include quality control results across all batches ##########
print("Creating Quality Control Values")

quality_control_results_df <- arrow::read_parquet("data/processed/build-data-products/blank_filtered_evaluated_qc_no_recovery.parquet") %>%
  dplyr::arrange(batch_number, dplyr::desc(evaluate_recovery_ratio_flag)) %>%
  data.frame()

quality_control_results_sheet <- xlsx::createSheet(wb, "Quality Control Values")
xlsx::addDataFrame(quality_control_results_df, sheet = quality_control_results_sheet, row.names = FALSE)


########## Sheet 3 - Add Calibration Curve Output #############
print("Creating Cal Curve Output")

calibration_curve_output_df <- arrow::read_parquet("data/processed/calibration-curve/calibration_curve_output_no_recov_filter.parquet") %>%
  dplyr::select(-run_count) %>%
  data.frame()

calibration_curve_output_sheet <- xlsx::createSheet(wb, "Cal Curve Output")
xlsx::addDataFrame(calibration_curve_output_df, sheet = calibration_curve_output_sheet, row.names = FALSE)

########## Sheet 4 - Add Analyte Concentration Summary #############
print("Creating Anlyte Conc Sum")

analyte_concentration_df <- arrow::read_parquet("data/processed/quantify-sample/analyte_concentration_no_recovery.parquet") %>%
  dplyr::select(
    batch_number,
    cartridge_number,
    individual_native_analyte_name,
    analyte_detection_flag,
    internal_standard_detection_flag,
    calibration_curve_range_category,
    r_squared,
    calibration_point,
    calibration_range,
    analyte_concentration_ng
  ) %>%
  data.frame()

analyte_concentration_sheet <- xlsx::createSheet(wb, "Anlyte Conc Sum")
xlsx::addDataFrame(analyte_concentration_df, sheet = analyte_concentration_sheet, row.names = FALSE)

########## Sheet 5 - Add Anlyte Concen Troubleshoot #############
print("Creating Anlyte Concen Troubleshoot")

analyte_concentration_df <- arrow::read_parquet("data/processed/quantify-sample/analyte_concentration_no_recovery.parquet") %>%
  dplyr::mutate(
    analyte_concentration_ng = ifelse(
      calibration_curve_range_category == "<LOD",
      NA,
      analyte_concentration_ng
    ),
    analyte_concentration_ng = ifelse(
      calibration_curve_range_category == "<LOQ",
      NA,
      analyte_concentration_ng
    )
  ) %>%
  data.frame()

calibration_curve_range_category_ref <- analyte_concentration_df %>%
  dplyr::select(
    batch_number,
    cartridge_number,
    individual_native_analyte_name,
    calibration_curve_range_category
  )

analyte_concentration_sheet <- xlsx::createSheet(wb, "Anlyte Concen Troubleshoot")
xlsx::addDataFrame(analyte_concentration_df, sheet = analyte_concentration_sheet, row.names = FALSE)


######## Sheet 6 - Add Blank Filtered Output #############
print("Creating Blnk Fltrd Anlyte Con")

blank_filtered_df <- arrow::read_parquet("data/processed/build-data-products/blank_filtered_analyte_concentration_no_recovery.parquet") %>%
  data.frame()

blank_filtered_sheet <- xlsx::createSheet(wb, "Blnk Fltrd Anlyte Con")
xlsx::addDataFrame(blank_filtered_df, sheet = blank_filtered_sheet, row.names = FALSE)

########## Sheet 7 - Add Field Blank Filtered Output #############
print("Creating Fld Blnk Fltrd Anlyte Con")

field_blank_filtered_df <- arrow::read_parquet("data/processed/build-data-products/field_blank_blank_filtered_analyte_concentration_no_recovery.parquet") %>%
  dplyr::left_join(
    calibration_curve_range_category_ref,
    by = c("batch_number", "cartridge_number", "individual_native_analyte_name")
  ) %>%
  data.frame()

field_blank_filtered_sheet <- xlsx::createSheet(wb, "Fld Blnk Fltrd Anlyte Con")
xlsx::addDataFrame(field_blank_filtered_df, sheet = field_blank_filtered_sheet, row.names = FALSE)

########## Sheet 8 - Analyte Concentration PPT #############
print("Creating Analyte Concentration ppt")

cal_curve_prep <- analyte_concentration_df %>%
  dplyr::distinct(
    batch_number,
    individual_native_analyte_name,
    calibration_point
  )

average_extract_blank_ref <- arrow::read_parquet(
  "data/processed/build-data-products/blank_filtered_no_recovery.parquet"
) %>%
  dplyr::select(
    batch_number,
    individual_native_analyte_name,
    average_extraction_blank_analyte_concentration_ng
  )

average_field_blank_ref <- arrow::read_parquet(
  "data/processed/build-data-products/field_blank_analyte_concentration_average_ng.parquet"
) %>%
  dplyr::select(
    individual_native_analyte_name,
    average_field_blank_analyte_concentration_ng
  )

# filtering down to just the analyte_concentration_ng to avoid
# column collisions
analyte_concentration_ng_ref <- analyte_concentration_df %>%
  dplyr::select(
    batch_number,
    cartridge_number,
    individual_native_analyte_name,
    analyte_concentration_ng
  )

analyte_concentration_ppt <- arrow::read_parquet("data/processed/build-data-products/analyte_concentration_ppt.parquet") %>%
  dplyr::left_join(
    cal_curve_prep,
    by = c("batch_number", "individual_native_analyte_name")
  ) %>%
  dplyr::left_join(
    calibration_curve_range_category_ref,
    by = c("batch_number", "cartridge_number", "individual_native_analyte_name")
  ) %>%
  dplyr::left_join(
    average_extract_blank_ref,
    by = c("batch_number", "individual_native_analyte_name")
  ) %>%
  dplyr::left_join(
    average_field_blank_ref,
    by = "individual_native_analyte_name"
  ) %>%
  dplyr::left_join(
    analyte_concentration_ng_ref,
    by = c("batch_number", "cartridge_number", "individual_native_analyte_name")
  ) %>%
  dplyr::mutate(
    analyte_concentration_ppt = ifelse(
      calibration_curve_range_category == "<LOQ",
      NA,
      analyte_concentration_ppt
    ),
    analyte_concentration_ppt = ifelse(
      calibration_curve_range_category == "<LOD",
      NA,
      analyte_concentration_ppt
    )
  ) %>%
  dplyr::mutate(
    positive_analyte_concentration_ng = ifelse(
      analyte_concentration_ng > 0 & !is.na(analyte_concentration_ng),
      "Positive",
      "Negative or NF"
    )
  ) %>%
  dplyr::select(
    batch_number,
    cartridge_number,
    county,
    sample_id,
    coordinates,
    calibration_point,
    calibration_curve_range_category,
    positive_analyte_concentration_ng,
    individual_native_analyte_name,
    sample_mass_g,
    analyte_concentration_ng,
    average_extraction_blank_analyte_concentration_ng,
    average_field_blank_analyte_concentration_ng,
    field_blank_blank_filtered_analyte_concentration_ng,
    analyte_concentration_ppt
  ) %>%
  data.frame()

analyte_concentration_ppt_sheet <- xlsx::createSheet(wb, "Analyte Concentration ppt")
xlsx::addDataFrame(analyte_concentration_ppt, sheet = analyte_concentration_ppt_sheet, row.names = FALSE)

########## Sheet 9 - Sample Count Summary #############
print("Creating a County Sample Count Summary")

county_sample_count_df <- analyte_concentration_ppt %>%
  dplyr::select(
    county,
    sample_id
  ) %>%
  dplyr::group_by(county) %>%
  dplyr::summarise(sample_count = dplyr::n_distinct(sample_id)) %>%
  data.frame()

county_sample_count_sheet <- xlsx::createSheet(wb, "County Sample Count")
xlsx::addDataFrame(county_sample_count_df, sheet = county_sample_count_sheet, row.names = FALSE)

########## Save out final file ############
cur_time <- format(Sys.time(), "%Y-%m-%d-%I-%M")

cur_time <- format(Sys.time(), "%Y-%m-%d-%I-%M")
if (Sys.info()["sysname"] == "Darwin") {
  xlsx::saveWorkbook(wb, paste0("/Users/aantonison/OneDrive/client/UniversityOfFlorida/", cur_time, "_summary_analysis_file.xlsx"))
}

if (Sys.info()["sysname"] == "Windows") {
  xlsx::saveWorkbook(wb, paste0("C:/Users/Alexander Antonison/OneDrive/client/UniversityOfFlorida/", cur_time, "_summary_analysis_file.xlsx"))
}

########## Separate Analyte Concentration PPT Transposed #############
print("Creating Analyte Concentration Wide File")

cur_time <- format(Sys.time(), "%Y-%m-%d-%I-%M")
filtered_df <- analyte_concentration_ppt %>%
  dplyr::filter(calibration_point >= 5) %>%
  dplyr::filter(calibration_curve_range_category == "Within Calibration Range" | calibration_curve_range_category == "Above Calibration Range") %>%
  dplyr::filter(analyte_concentration_ng > 0) %>%
  dplyr::select(
    batch_number,
    cartridge_number,
    sample_id,
    county,
    coordinates,
    individual_native_analyte_name,
    analyte_concentration_ppt,
  ) %>%
  tidyr::pivot_wider(names_from = individual_native_analyte_name, values_from = analyte_concentration_ppt, names_sep = "")

unfiltered_df <- analyte_concentration_ppt %>%
  dplyr::select(
    batch_number,
    cartridge_number,
    sample_id,
    county,
    coordinates,
    individual_native_analyte_name,
    analyte_concentration_ppt,
  ) %>%
  tidyr::pivot_wider(names_from = individual_native_analyte_name, values_from = analyte_concentration_ppt, names_sep = "")

cur_time <- format(Sys.time(), "%Y-%m-%d-%I-%M")
if (Sys.info()["sysname"] == "Darwin") {
  readr::write_excel_csv(filtered_df, paste0("/Users/aantonison/OneDrive/client/UniversityOfFlorida/filtered_", cur_time, "_analyte_concentration_ppt_wide.csv"),
    na = ""
  )
  readr::write_excel_csv(unfiltered_df, paste0("/Users/aantonison/OneDrive/client/UniversityOfFlorida/unfiltered_", cur_time, "_analyte_concentration_ppt_wide.csv"),
    na = ""
  )
}

if (Sys.info()["sysname"] == "Windows") {
  readr::write_excel_csv(filtered_df, paste0("C:/Users/Alexander Antonison/OneDrive/client/UniversityOfFlorida/filtered_", cur_time, "_analyte_concentration_ppt_wide.csv"),
    na = ""
  )
  readr::write_excel_csv(unfiltered_df, paste0("C:/Users/Alexander Antonison/OneDrive/client/UniversityOfFlorida/unfiltered_", cur_time, "_analyte_concentration_ppt_wide.csv"),
    na = ""
  )
}
