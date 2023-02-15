library(magrittr)

####################################
# Process Batch File Info
####################################

#' Read in the batch sample excel file
#' @param file_name A string of the file_name where the file is located
#' @importFrom magrittr %>%
read_batch_file <- function(file_name) {
  # read in the excel sheets to loop through
  batch_sheets <- readxl::excel_sheets(file_name)

  # instantiate a base tibble
  combined_tibble <- dplyr::tibble()

  for (sheet in batch_sheets) {
    print(sheet)
    excel_sheet_data <- readxl::read_excel(
      file_name,
      sheet = sheet,
      col_types = "text",
      na = c("N/A", "NA", "Sample not found", "#VALUE!")
    )

    # add sheet name to dataframe
    excel_sheet_data$batch_number <- sheet

    # combine the sheets together
    combined_tibble <- dplyr::bind_rows(
      excel_sheet_data,
      combined_tibble
    )
  }

  return(combined_tibble)
}

#' Process combined batch file
#' @param data A dataframe that has all of the sheets combined
#' @importFrom magrittr %>%
process_batch_file <- function(data) {
  coordinates <- full_bottle_mass <- empty_bottle_mass <- NULL
  sample_mass_g <- batch_number <- NULL

  # clean up column names
  data %>%
    # clean up names of columns for processing
    janitor::clean_names() %>%
    # temporarily rename coordinates so it can be merged
    dplyr::rename(temp_coordinates = coordinates) %>%
    # merge coordinates and gps_coordinates together
    tidyr::unite(
      "coordinates",
      c("temp_coordinates", "gps_coordinates"),
      remove = TRUE,
      na.rm = TRUE
    ) %>%
    # rename extra column name
    dplyr::rename(
      notes = "x11"
    ) %>%
    # fix column data types
    dplyr::mutate(
      full_bottle_mass = as.double(full_bottle_mass),
      empty_bottle_mass = as.double(empty_bottle_mass),
      sample_mass_g = as.double(sample_mass_g),
    ) %>%
    # puts the batch number in the front of the dataframe
    dplyr::relocate(
      batch_number
    ) %>%
    # write dataframe out to csv file
    arrow::write_parquet(
      sink = "data/processed/processed_extract_batch_source.parquet"
    ) %>%
    readr::write_excel_csv("data/processed/processed_extract_batch_source.csv")
}

####################################
# Process IS_Mix_source File
####################################

#' Extract IS Mixes from Excel file
#' @param file_name A string of the file_name where the file is located
#' @param sheet_name The name of the excel sheet
#' @importFrom magrittr %>%
extraact_is_mix <- function(file_name, sheet_name) {
  mix_name <- NULL

  # MPFAC-24ES

  is_label_mpfac_24es <- readxl::read_excel(
    file_name,
    sheet = sheet_name,
    range = "A33:A51",
    col_names = c("mix_label")
  )
  is_mix_mpfac_24es <- readxl::read_excel(
    file_name,
    sheet = sheet_name,
    range = "G33:G51",
    col_names = c("IS_mix_ppb")
  )
  df_mpfac_24es <- dplyr::bind_cols(
    is_label_mpfac_24es,
    is_mix_mpfac_24es
  )

  df_mpfac_24es$mix_name <- "MPFAC-24ES"

  df_mpfac_24es <- dplyr::relocate(
    df_mpfac_24es,
    mix_name
  )

  # MFTA-MXA

  is_label_mfta_mxa <- readxl::read_excel(
    file_name,
    sheet = sheet_name,
    range = "A54:A56",
    col_names = c("mix_label")
  )
  is_mix_mfta_mxa <- readxl::read_excel(
    file_name,
    sheet = sheet_name,
    range = "G54:G56",
    col_names = c("IS_mix_ppb")
  )
  df_mfta_mxa <- dplyr::bind_cols(
    is_label_mfta_mxa,
    is_mix_mfta_mxa
  )
  df_mfta_mxa$mix_name <- "MFTA-MXA"
  df_mfta_mxa <- dplyr::relocate(
    df_mfta_mxa,
    mix_name
  )

  # Extra_IS_Mix

  is_label_extra_is_mix <- readxl::read_excel(
    file_name,
    sheet = sheet_name,
    range = "A59:A63",
    col_names = c("mix_label")
  )
  is_mix_extra_is_mix <- readxl::read_excel(
    file_name,
    sheet = sheet_name,
    range = "G59:G63",
    col_names = c("IS_mix_ppb")
  )
  df_extra_is_mix <- dplyr::bind_cols(
    is_label_extra_is_mix,
    is_mix_extra_is_mix
  )
  df_extra_is_mix$mix_name <- "Extra_IS_Mix"
  df_extra_is_mix <- dplyr::relocate(
    df_extra_is_mix,
    mix_name
  )

  is_mix_df <- dplyr::bind_rows(df_mpfac_24es, df_mfta_mxa, df_extra_is_mix)

  is_mix_df$sheet_name <- sheet_name

  is_mix_df <- dplyr::relocate(is_mix_df, sheet_name)

  return(is_mix_df)
}

#' Process sheets in IS Mix File
#' @param file_name The name of the IS Mix Excel File
process_is_excel <- function(file_name) {
  is_mix_sheets <- readxl::excel_sheets(file_name)

  combined_is_df <- dplyr::tibble()

  for (sheet in is_mix_sheets) {
    temp_df <- extraact_is_mix(file_name, sheet)

    combined_is_df <- dplyr::bind_rows(
      temp_df,
      combined_is_df
    )
  }

  arrow::write_parquet(
    combined_is_df,
    sink = "data/processed/is_mix_source.parquet"
  )
  readr::write_excel_csv(
    combined_is_df, "data/processed/is_mix_source.csv"
  )
}

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
    col_names = c("analyte_concentration", "a", "b", "c", "d", "e", "cal_curve")
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
    col_names = c("isotopically_labeled_standard", "a", "b", "c", "d", "e", "cal_curve")
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
      print(sheet)

      temp_analyte <- extract_analyte_source(file_name, sheet)

      temp_analyte$calibration_level <- sheet

      analyte_source_df <- dplyr::bind_rows(
        temp_analyte,
        analyte_source_df
      )

      temp_is_label <- extract_is_label(file_name, sheet)

      temp_is_label$calibration_level <- sheet

      is_label_df <- dplyr::bind_rows(
        temp_is_label,
        is_label_df
      )
    }
  }

  # select columns of interest
  analyte_source_df <- analyte_source_df %>%
    dplyr::select(
      calibration_level,
      analyte_concentration,
      cal_curve
    )

  is_label_df <- is_label_df %>%
    dplyr::select(
      calibration_level,
      isotopically_labeled_standard,
      cal_curve
    )

  # write files out to parquet and excel
  arrow::write_parquet(
    analyte_source_df,
    sink = "data/processed/analyte_concentrations.parquet"
  )
  readr::write_excel_csv(
    analyte_source_df, "data/processed/analyte_concentrations.csv"
  )

  arrow::write_parquet(
    is_label_df,
    sink = "data/processed/is_label_source.parquet"
  )
  readr::write_excel_csv(
    is_label_df, "data/processed/is_label_source.csv"
  )
}