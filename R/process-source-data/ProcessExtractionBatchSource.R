library(magrittr)

# This script processes and cleans up the Extraction_Batches_source.xlsx
# and creates a single table called extraction_batch_source.csv

####################################
# Process Batch File Info
####################################

if (fs::file_exists("data/source/reference/Extraction_Batches_source.xlsx")) {
  print("Source Data Downloaded")
} else {
  # pull source data from S3
  source("R/utility/GetSourceData.R")
}

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
      batch_number = readr::parse_number(batch_number)
    ) %>%
    # puts the batch number in the front of the dataframe
    dplyr::relocate(
      batch_number
    ) %>%
    # write dataframe out to csv file
    arrow::write_parquet(
      sink = "data/processed/extraction_batch_source.parquet"
    ) %>%
    # replace NA values with blanks to clean
    # up output file
    tidyr::replace_na(
      list(
        notes = ""
      )
    ) %>%
    readr::write_excel_csv("data/processed/extraction_batch_source.csv")
}

# process Extraction_Batches_source.xlsx
df <- read_batch_file("data/source/reference/Extraction_Batches_source.xlsx")
process_batch_file(df)
