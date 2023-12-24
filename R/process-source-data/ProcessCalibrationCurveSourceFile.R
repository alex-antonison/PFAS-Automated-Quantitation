# This script takes in the Sep2021Calibration_Curve_source.xlsx file
# and transforms it into two tables:
# native_analyte_concentration
# internal_standard_concentration

####################################
# Process Calibration Curve Source File
####################################

#' Extract Analyte Source Values
#' @param file_name A string of the file_name where the file is located
#' @param sheet_name The name of the excel sheet
extract_analyte_source <- function(file_name, sheet_name) {
  sheet_range_cal_1 <- "A13:G123"
  sheet_range_cal_other <- "A15:G125"

  if (sheet_name == "Cal_1_Sep2021") {
    sheet_range_col <- sheet_range_cal_1
  } else {
    sheet_range_col <- sheet_range_cal_other
  }

  analyte_df <- readxl::read_excel(
    file_name,
    sheet = sheet_name,
    range = sheet_range_col,
    col_names = c("individual_native_analyte_name", "a", "b", "c", "d", "e", "native_analyte_concentration_ppt")
  )

  return(analyte_df)
}

#' Extract IS Label Mix Values
#' @param file_name A string of the file_name where the file is located
#' @param sheet_name The name of the excel sheet
extract_is_label <- function(file_name, sheet_name) {
  sheet_range_cal_1 <- "A126:G152"
  sheet_range_cal_other <- "A128:G154"

  if (sheet_name == "Cal_1_Sep2021") {
    sheet_range_col <- sheet_range_cal_1
  } else {
    sheet_range_col <- sheet_range_cal_other
  }

  iso_label_df <- readxl::read_excel(
    file_name,
    sheet = sheet_name,
    range = sheet_range_col,
    col_names = c("internal_standard_name", "a", "b", "c", "d", "e", "internal_standard_concentration_ppt")
  )

  return(iso_label_df)
}

#' Process Cal Source Values
#' @param file_name The name of the file to be processed
process_cal_source <- function(file_name) {
  # initialize empty dataframes for combining
  # sheets
  analyte_source_df <- dplyr::tibble()
  is_label_df <- dplyr::tibble()


  for (sheet in readxl::excel_sheets(file_name)) {
    # only want to run the non-final sheet
    if (stringr::str_detect(sheet, "Cal_")) {
      # process sheet name into
      # calibration level and
      # calibration mix
      split_values <- stringr::str_split(sheet, "_")[[1]]

      calibration_level <- paste(
        split_values[1],
        split_values[2],
        sep = "_"
      )

      calibration_mix <- split_values[3]

      ########
      # run native_analyte code
      ########
      # pull in sheet values
      temp_analyte <- extract_analyte_source(file_name, sheet)

      # add in calibration_level and calibration_mix columns
      temp_analyte$calibration_level <- calibration_level
      temp_analyte$calibration_mix <- calibration_mix

      analyte_source_df <- dplyr::bind_rows(
        temp_analyte,
        analyte_source_df
      )

      ########
      # run internal standard code
      ########

      temp_is_label <- extract_is_label(file_name, sheet)

      temp_is_label$calibration_level <- calibration_level
      temp_is_label$calibration_mix <- calibration_mix

      is_label_df <- dplyr::bind_rows(
        temp_is_label,
        is_label_df
      )
    }
  }

  # select columns of interest
  export_analyte_source_df <- analyte_source_df %>%
    dplyr::select(
      calibration_level,
      calibration_mix,
      individual_native_analyte_name,
      native_analyte_concentration_ppt
    ) %>%
    # logic to combine Linear and Branched PFOS into "∑ PFOS"
    dplyr::mutate(
      individual_native_analyte_name = dplyr::if_else(
        (individual_native_analyte_name == "Linear PFOS" | individual_native_analyte_name == "Branched PFOS"),
        "∑ PFOS",
        individual_native_analyte_name
      )
    ) %>%
    dplyr::group_by(
      calibration_level,
      calibration_mix,
      individual_native_analyte_name
    ) %>%
    dplyr::summarise(
      native_analyte_concentration_ppt = sum(native_analyte_concentration_ppt),
      .groups = "keep"
    ) %>%
    dplyr::ungroup()

  is_label_df <- is_label_df %>%
    dplyr::select(
      calibration_level,
      calibration_mix,
      internal_standard_name,
      internal_standard_concentration_ppt
    )

  # write files out to parquet and excel
  arrow::write_parquet(
    export_analyte_source_df,
    sink = "data/processed/reference/native_analyte_concentration.parquet"
  )
  readr::write_excel_csv(
    export_analyte_source_df,
    "data/processed/reference/native_analyte_concentration.csv"
  )

  arrow::write_parquet(
    is_label_df,
    sink = "data/processed/reference/internal_standard_concentration.parquet"
  )
  readr::write_excel_csv(
    is_label_df, "data/processed/reference/internal_standard_concentration.csv"
  )
}

# Process Sep2021Calibration_Curve_source.xlsx
process_cal_source("data/source/reference/Sep2021Calibration_Curve_source.xlsx")
