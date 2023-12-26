# This script processes and cleans up the Extraction_Batches_source.xlsx
# and creates a single table called extraction_batch_source.csv

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
    excel_sheet_data <- readxl::read_excel(
      file_name,
      .name_repair = "unique_quiet",
      sheet = sheet,
      col_types = "text",
      na = c("N/A", "NA", "Sample not found", "#VALUE!")
    )

    # add sheet name to dataframe
    excel_sheet_data$batch_number <- sheet

    # combine the sheets together
    combined_tibble <- suppressMessages(
      dplyr::bind_rows(
        excel_sheet_data,
        combined_tibble
      )
    )
  }

  return(combined_tibble)
}




data <- read_batch_file("data/source/reference/Extraction_Batches_source.xlsx")

coordinates <- full_bottle_mass <- empty_bottle_mass <- NULL
sample_mass_g <- batch_number <- NULL

exclude_filename <- arrow::read_parquet(
  "data/processed/reference/batch_filename_error.parquet"
) %>%
  dplyr::mutate(
    # set flag to false since files filenames in the error config
    # need to be removed
    keep_filename_flag = FALSE
  ) %>%
  dplyr::mutate(
    cartridge_number = filename
  ) %>%
  dplyr::select(
    batch_number,
    cartridge_number,
    keep_filename_flag
  )


# clean up column names
data %>%
  # clean up names of columns for processing
  janitor::clean_names() %>%
  dplyr::mutate(
    batch_number = readr::parse_number(batch_number)
  ) %>%
  # temporarily rename coordinates so it can be merged
  dplyr::left_join(
    exclude_filename,
    by = c("batch_number", "cartridge_number")
  ) %>%
  dplyr::mutate(
    keep_filename_flag = dplyr::if_else(is.na(keep_filename_flag),
      TRUE,
      keep_filename_flag
    )
  ) %>%
  dplyr::filter(keep_filename_flag) %>%
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
    cartridge_number = readr::parse_number(cartridge_number)
  ) %>%
  # puts the batch number in the front of the dataframe
  dplyr::relocate(
    batch_number
  ) %>%
  # write dataframe out to csv file
  arrow::write_parquet(
    sink = "data/processed/reference/extraction_batch_source.parquet"
  ) %>%
  # replace NA values with blanks to clean
  # up output file
  tidyr::replace_na(
    list(
      notes = ""
    )
  ) %>%
  readr::write_excel_csv("data/processed/reference/extraction_batch_source.csv")
