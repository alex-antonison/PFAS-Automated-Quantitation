## Need to restart R Session prior to running this script

library(magrittr)

options(java.parameters = "-Xmx30720m")

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
  dplyr::select(-run_count) %>% 
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



########## Save out final file ############
cur_time <- format(Sys.time(), "%Y-%m-%d-%I-%M")
xlsx::saveWorkbook(wb, paste0("/Users/aantonison/OneDrive/client/UniversityOfFlorida/", cur_time, "_summary_analysis_file_1.xlsx"))