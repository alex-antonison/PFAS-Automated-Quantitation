####################################
# Process Measured Data
####################################


read_in_raw_data <- function(source_file_name, sheet_name, source_type) {
  # read in the sheet and skip the top 4 names
  df <- readxl::read_xls(file_name, sheet_name, skip = 4, .name_repair = "unique_quiet") %>%
    # clean up the column names
    janitor::clean_names() %>%
    # remove instances where sample_type is null since this
    # will remove unnecessary records from the end
    dplyr::filter(!is.na(sample_type)) %>%
    dplyr::mutate(
      sheet_name = sheet_name,
      source_file_name = source_file_name,
      source_type = source_type
    ) %>%
    dplyr::select(
      source_file_name,
      source_type,
      sheet_name,
      filename,
      area
    )

  return(df)
}

#' A function that takes care of checking if an analyte matches a reference
#' native analyte name
#' @param analyte_name The native analyte name being checked
#' @param match_list A list of native analytes to check against
check_analyte_name <- function(analyte_name, match_list) {
  analyte_name <- stringr::str_to_lower(analyte_name)
  match_ist <- stringr::str_to_lower(match_list$individual_native_analyte_name)

  if (analyte_name %in% match_ist) {
    analyte_match <- "Match Found"
  } else {
    analyte_match <- "No Match Found"
  }

  return(analyte_match)
}

#' Function to pull out the batch number from a source file. It is expecting
#' the source file to be in the raw_data directory and to have the batch number
#' after Set like "data/source/raw_data/Set2_139_273_Short.XLS" which this
#' would be Batch Number 2
#' @param filename The name of the file being processed
get_batch_number <- function(filename) {
  # pull batch number from source file name
  str_start <- stringr::str_locate(filename, "Set")[[1, "end"]]
  # find the next underscore after it sees Set
  underscore_return <- stringr::str_locate_all(filename, "_")
  str_end_df <- as.data.frame(underscore_return) %>%
    dplyr::filter(
      end > str_start
    )
  str_end <- str_end_df[1, "end"]
  batch_number <- stringr::str_sub(filename, str_start + 1, str_end - 1)
  # convert to integer
  batch_number <- as.integer(batch_number)

  return(batch_number)
}


#' A that takes care of processing all sheets in a source data file
#' @param file_name A path to where the file is located
process_raw_file <- function(file_name) {
  # initialize dataframes for adding files
  data_df <- dplyr::tibble()
  naming_df <- dplyr::tibble()

  batch_number <- get_batch_number(file_name)

  remove_analytes <- arrow::read_parquet(
    "data/processed/reference/remove_analytes_from_study.parquet"
  ) %>%
    dplyr::select(
      analyte_name,
      native_is
    )

  remove_analytes_by_batch <- arrow::read_parquet(
    "data/processed/reference/remove_analytes_from_batch.parquet"
  ) %>%
    dplyr::filter(batch_number == batch_number) %>%
    dplyr::select(
      analyte_name,
      native_is
    )

  remove_analytes_combined <- dplyr::bind_rows(
    remove_analytes,
    remove_analytes_by_batch
  ) %>%
    dplyr::distinct(analyte_name)

  # read in matching file for internal standards and
  # native analyte
  n_analyte_is_match <- arrow::read_parquet(
    "data/processed/mapping/native_analyte_internal_standard_mapping.parquet"
  )

  # loop through each sheet in the source excel file
  for (sheet in readxl::excel_sheets(file_name)) {
    batch_number <- get_batch_number(file_name)

    # setting null for non-native analytes
    analyte_match <- NA

    # set to NA initially so it doesn't incorrectly
    # set an incorrect value
    source_type <- NA

    sheet_name_length <- stringr::str_length(sheet)
    last_two_char <- stringr::str_sub(sheet, -2)
    last_four_analyte <- stringr::str_sub(sheet, -4)

    # ignore non-data sheets
    if (sheet %in% c("Component", "mdlCalcs")) next

    # if an analyte or internal standard is in the list
    # it should not be processed and excluded from the study
    if (sheet %in% remove_analytes_combined$analyte_name) next

    # check if there is EPA in the sheet name
    if (stringr::str_detect(sheet, "_EPA")) {
      source_type <- "EPA"
      temp_data_df <- read_in_raw_data(file_name, sheet, source_type = "EPA")

      # check if there is _3M in the sheet name
    } else if (stringr::str_detect(sheet, "_3M")) {
      source_type <- "3M"
      temp_data_df <- read_in_raw_data(file_name, sheet, source_type = "3M")

      # check if there is an internal standard match
    } else if (sheet %in% n_analyte_is_match$internal_standard_name) {
      source_type <- "internal_standard"
      temp_data_df <- read_in_raw_data(file_name, sheet, source_type = "internal_standard")
      # check to see if there is a _1 or _2 in the name as
      # this indicates it is a native analyte
    } else if (last_two_char == "_1" || last_two_char == "_2") {
      source_type <- "native_analyte"

      temp_data_df <- read_in_raw_data(file_name, sheet, source_type = "native_analyte")

      # checking to see if analyte name is found in document
      analyte_name <- stringr::str_sub(sheet, 1, sheet_name_length - 2)
      analyte_match <- check_analyte_name(analyte_name, n_analyte_is_match)
      temp_data_df$analyte_match <- analyte_match

      # checking for Peaks
    } else if (last_four_analyte == "Peak") {
      source_type <- "native_analyte"

      analyte_name <- stringr::str_sub(sheet, 0, sheet_name_length - 10)

      # checking to see if analyte name is found in document
      analyte_match <- check_analyte_name(analyte_name, n_analyte_is_match)

      temp_data_df <- read_in_raw_data(file_name, sheet, source_type = "native_analyte")

      # removing _1stPeak from the end of each of the sheets that match this name
      temp_data_df$sheet_name <- stringr::str_sub(sheet, 0, sheet_name_length - 8)
      temp_data_df$analyte_match <- analyte_match
    } else if (last_four_analyte == "eaks") {
      source_type <- "native_analyte"

      temp_data_df <- read_in_raw_data(file_name, sheet, source_type = "native_analyte")

      # removing _2peaks from the end of each of the sheets that match this name
      temp_data_df$sheet_name <- stringr::str_sub(sheet, 0, sheet_name_length - 7)

      # checking to see if analyte name is found in document
      analyte_name <- stringr::str_sub(sheet, 0, sheet_name_length - 9)
      analyte_match <- check_analyte_name(analyte_name, n_analyte_is_match)
      temp_data_df$analyte_match <- analyte_match
    } else if (sheet == "diSamPAP") {
      source_type <- "native_analyte"

      analyte_match <- check_analyte_name(sheet, n_analyte_is_match)
      temp_data_df <- read_in_raw_data(file_name, sheet, source_type = "native_analyte")
      # adding an _1 in order to have it line up with other naming conventions
      temp_data_df$sheet_name <- "diSamPAP_1"
      temp_data_df$analyte_match <- analyte_match

      # if no match is found, will flag as other and review
      # to determine if logic needs to be adjusted
    } else {
      source_type <- "other"
      temp_data_df <- read_in_raw_data(file_name, sheet, source_type = "other")
    }

    # construct the temp naming df
    temp_naming_df <- dplyr::tibble(
      file_name = file_name,
      sheet = sheet,
      source_type = source_type,
      analyte_match = analyte_match,
      batch_number = batch_number
    )
    naming_df <- dplyr::bind_rows(
      naming_df,
      temp_naming_df
    )

    # add batch number to final df
    temp_data_df$batch_number <- batch_number

    # combine the final df and the naming df
    data_df <- dplyr::bind_rows(
      data_df,
      temp_data_df
    )
  }
  return(list(data_df, naming_df))
}

####################################
# Run Processing Function for all files
####################################



combined_data_df <- dplyr::tibble()
combined_naming_df <- dplyr::tibble()

source_file_list <- fs::dir_ls("data/source/raw_data/")

# This loops over each of the source files in the
# previously configured source_file_list
for (file_name in source_file_list) {
  df_list <- process_raw_file(file_name)

  # combines the different processed data file
  # into a single file
  combined_data_df <- dplyr::bind_rows(
    combined_data_df,
    df_list[[1]]
  )

  # combines the different naming dataframes into a single
  # table
  combined_naming_df <- dplyr::bind_rows(
    combined_naming_df,
    df_list[[2]]
  )
}

# troubleshoot naming
readr::write_csv(
  combined_naming_df,
  "data/processed/troubleshoot/raw_data_processing_naming.csv"
)

# write full output to parquet for processing
arrow::write_parquet(
  combined_data_df,
  sink = "data/processed/source/full_raw_data.parquet"
)

# write full output to csv
readr::write_csv(
  combined_data_df,
  "data/processed/source/full_raw_data.csv"
)
