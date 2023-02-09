library(dplyr)
library(readxl)
library(stringr)
library(janitor)
library(readr)
library(arrow)
library(tidyr)

source("R/GetSourceData.R")

#' Read in the batch sample excel file
#' @param file_name A string of the file_name where the file is located
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
      sink = "inst/extdata/processed/processed_extract_batch_source.parquet"
    )
}

df <- read_batch_file("inst/extdata/source/Extraction_Batches_source.xlsx")

process_batch_file(df)

clean_df <- arrow::read_parquet(
  "inst/extdata/processed/processed_extract_batch_source.parquet"
)
