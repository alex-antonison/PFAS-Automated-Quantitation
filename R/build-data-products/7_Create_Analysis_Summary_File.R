library(magrittr)

options(java.parameters = "-Xmx1000000m")

# set up initial workbook
wb <- xlsx::createWorkbook()


########## Sheet 1 - Build a quality control pass fail across batches ##########
quality_control_pass_fail_df <- arrow::read_parquet("data/processed/build-data-products/blank_filtered_evaluated_qc_no_recovery.parquet") %>%
  dplyr::select(-quality_control_exists_flag, -quality_control_adjust_flag) %>%
  dplyr::filter(!is.na(evaluate_recovery_ratio_flag)) %>%
  dplyr::group_by(batch_number, evaluate_recovery_ratio_flag) %>%
  dplyr::summarise(count = dplyr::n()) %>%
  dplyr::arrange(batch_number) %>%
  data.frame()

quality_control_pass_fail_sheet <- xlsx::createSheet(wb, "Pass Fail Summary")
xlsx::addDataFrame(quality_control_pass_fail_df, sheet = quality_control_pass_fail_sheet, row.names = FALSE)


########## Sheet 2 -  Include quality control results across all batches ##########
quality_control_results_df <- arrow::read_parquet("data/processed/build-data-products/blank_filtered_evaluated_qc_no_recovery.parquet") %>%
  dplyr::arrange(batch_number, dplyr::desc(evaluate_recovery_ratio_flag)) %>%
  data.frame()

quality_control_results_sheet <- xlsx::createSheet(wb, "Quality Control Values")
xlsx::addDataFrame(quality_control_results_df, sheet = quality_control_results_sheet, row.names = FALSE)


########## Sheet 3 - Add Calibration Curve Output #############
calibration_curve_output_df <- arrow::read_parquet("data/processed/calibration-curve/calibration_curve_output_no_recov_filter.parquet") %>%
  data.frame()

calibration_curve_output_sheet <- xlsx::createSheet(wb, "Cal Curve Output")
xlsx::addDataFrame(calibration_curve_output_df, sheet = calibration_curve_output_sheet, row.names = FALSE)

########## Sheet 4 - Add Analyte Concentration Summary #############

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

########## Sheet 5 - Add Analyte Concentration Output #############

analyte_concentration_df <- arrow::read_parquet("data/processed/quantify-sample/analyte_concentration_no_recovery.parquet") %>%
  data.frame()

analyte_concentration_sheet <- xlsx::createSheet(wb, "Analyte Concentration Troubleshoot")
xlsx::addDataFrame(analyte_concentration_df, sheet = analyte_concentration_sheet, row.names = FALSE)

########## Sheet 6 - Add Blank Filtered Output #############

blank_filtered_df <- arrow::read_parquet("data/processed/build-data-products/blank_filtered_analyte_concentration_no_recovery.parquet") %>%
  data.frame()

blank_filtered_sheet <- xlsx::createSheet(wb, "Blnk Fltrd Anlyte Con")
xlsx::addDataFrame(blank_filtered_df, sheet = blank_filtered_sheet, row.names = FALSE)

########## Sheet 7 - Add Field Blank Filtered Output #############

field_blank_filtered_df <- readr::read_csv("data/processed/build-data-products/field_blank_blank_filtered_analyte_concentration_no_recovery.csv") %>%
  data.frame()

field_blank_filtered_sheet <- xlsx::createSheet(wb, "Fld Blnk Fltrd Anlyte Con")
xlsx::addDataFrame(field_blank_filtered_df, sheet = field_blank_filtered_sheet, row.names = FALSE)

########## Sheet 8 - Analyte Concentration PPT #############

cal_curve_prep <- analyte_concentration_df %>%
  dplyr::distinct(
    batch_number,
    individual_native_analyte_name,
    calibration_point
  )

analyte_concentration_ppt <- readr::read_csv("data/processed/build-data-products/analyte_concentration_ppt.csv") %>%
  dplyr::left_join(
    cal_curve_prep,
    by = c("batch_number", "individual_native_analyte_name")
  ) %>%
  data.frame()

analyte_concentration_ppt %>%
  dplyr::group_by(
    batch_number,
    cartridge_number,
    individual_native_analyte_name
  ) %>%
  dplyr::summarize(count = dplyr::n()) %>%
  dplyr::filter(count > 1)


analyte_concentration_ppt_sheet <- xlsx::createSheet(wb, "Analyte Concentration ppt")
xlsx::addDataFrame(analyte_concentration_ppt, sheet = analyte_concentration_ppt_sheet, row.names = FALSE)

########## Save out final file ############
cur_time <- format(Sys.time(), "%Y-%m-%d-%I-%M")
xlsx::saveWorkbook(wb, paste0("/Users/aantonison/OneDrive/client/UniversityOfFlorida/", cur_time, "_summary_analysis_file.xlsx"))


########## Separate Analyte Concentration PPT Transposed #############

analyte_concentration_ppt_transposed <- analyte_concentration_ppt %>%
  dplyr::select(
    batch_number,
    cartridge_number,
    sample_id,
    county,
    coordinates,
    calibration_point,
    individual_native_analyte_name,
    analyte_concentration_ppt
  ) %>%
  tidyr::pivot_wider(names_from = individual_native_analyte_name, values_from = analyte_concentration_ppt, names_sep = "") %>%
  readr::write_excel_csv(paste0("/Users/aantonison/OneDrive/client/UniversityOfFlorida/", cur_time, "_analyte_concentration_ppt_wide.csv"),
    na = ""
  )
