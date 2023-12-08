## Need to restart R Session prior to running this script

library(magrittr)

options(java.parameters = "-Xmx30720m")

# set up initial workbook
wb <- xlsx::createWorkbook()

########## Sheet 5 - Add Analyte Concentration Output #############

analyte_concentration_df <- arrow::read_parquet("data/processed/quantify-sample/analyte_concentration_no_recovery.parquet") %>%
  data.frame()

analyte_concentration_sheet <- xlsx::createSheet(wb, "Analyte Concentration Troubleshoot")
xlsx::addDataFrame(analyte_concentration_df, sheet = analyte_concentration_sheet, row.names = FALSE)


######## Sheet 6 - Add Blank Filtered Output #############

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

analyte_concentration_ppt_sheet <- xlsx::createSheet(wb, "Analyte Concentration ppt")
xlsx::addDataFrame(analyte_concentration_ppt, sheet = analyte_concentration_ppt_sheet, row.names = FALSE)

########## Save out final file ############
cur_time <- format(Sys.time(), "%Y-%m-%d-%I-%M")
xlsx::saveWorkbook(wb, paste0("/Users/aantonison/OneDrive/client/UniversityOfFlorida/", cur_time, "_summary_analysis_file_2.xlsx"))


########## Separate Analyte Concentration PPT Transposed #############

cur_time <- format(Sys.time(), "%Y-%m-%d-%I-%M")
analyte_concentration_ppt %>%
  dplyr::filter(calibration_point >= 5) %>%
  dplyr::select(
    batch_number,
    cartridge_number,
    sample_id,
    county,
    coordinates,
    individual_native_analyte_name,
    analyte_concentration_ppt,
  ) %>%
  tidyr::pivot_wider(names_from = individual_native_analyte_name, values_from = analyte_concentration_ppt, names_sep = "") %>%
  readr::write_excel_csv(paste0("/Users/aantonison/OneDrive/client/UniversityOfFlorida/", cur_time, "_analyte_concentration_ppt_wide.csv"),
    na = ""
  )
