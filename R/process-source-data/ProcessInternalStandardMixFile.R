library(magrittr)

# Processes the IS_Mix_source.xlsx file into a single table
# called internal_standard_mix

####################################
# Process IS_Mix_source File
####################################

if (fs::file_exists("data/source/IS_Mix_source.xlsx")) {
  print("Source Data Downloaded")
} else {
  # pull source data from S3
  source("R/utility/GetSourceData.R")
}

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
    col_names = c("internal_standard_concentration_name")
  )
  is_mix_mpfac_24es <- readxl::read_excel(
    file_name,
    sheet = sheet_name,
    range = "G33:G51",
    col_names = c("internal_standard_concentration_ppb")
  )
  df_mpfac_24es <- dplyr::bind_cols(
    is_label_mpfac_24es,
    is_mix_mpfac_24es
  )

  df_mpfac_24es$stock_mix <- "MPFAC-24ES"

  df_mpfac_24es <- dplyr::relocate(
    df_mpfac_24es,
    stock_mix
  )

  # MFTA-MXA

  is_label_mfta_mxa <- readxl::read_excel(
    file_name,
    sheet = sheet_name,
    range = "A54:A56",
    col_names = c("internal_standard_concentration_name")
  )
  is_mix_mfta_mxa <- readxl::read_excel(
    file_name,
    sheet = sheet_name,
    range = "G54:G56",
    col_names = c("internal_standard_concentration_ppb")
  )
  df_mfta_mxa <- dplyr::bind_cols(
    is_label_mfta_mxa,
    is_mix_mfta_mxa
  )
  df_mfta_mxa$stock_mix <- "MFTA-MXA"
  df_mfta_mxa <- dplyr::relocate(
    df_mfta_mxa,
    stock_mix
  )

  # Extra_IS_Mix

  is_label_extra_is_mix <- readxl::read_excel(
    file_name,
    sheet = sheet_name,
    range = "A59:A63",
    col_names = c("internal_standard_concentration_name")
  )
  is_mix_extra_is_mix <- readxl::read_excel(
    file_name,
    sheet = sheet_name,
    range = "G59:G63",
    col_names = c("internal_standard_concentration_ppb")
  )
  df_extra_is_mix <- dplyr::bind_cols(
    is_label_extra_is_mix,
    is_mix_extra_is_mix
  )
  df_extra_is_mix$stock_mix <- "Extra_IS_Mix"
  df_extra_is_mix <- dplyr::relocate(
    df_extra_is_mix,
    stock_mix
  )

  is_mix_df <- dplyr::bind_rows(df_mpfac_24es, df_mfta_mxa, df_extra_is_mix)


  internal_standard_mix <- stringr::str_replace(
    sheet_name,
    "IS-Mix_",
    ""
  )

  is_mix_df$internal_standard_mix <- internal_standard_mix

  is_mix_df <- dplyr::relocate(is_mix_df, internal_standard_mix)

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
    sink = "data/processed/internal_standard_mix.parquet"
  )
  readr::write_excel_csv(
    combined_is_df, "data/processed/internal_standard_mix.csv"
  )
}

# Process IS_mix_source.xlsx file
process_is_excel("data/source/IS_Mix_source.xlsx")
