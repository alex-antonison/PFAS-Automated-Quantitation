library(magrittr)

####################################
# Get Source Data if Missing
####################################


reference_file_list <- "data/source/Native_analyte_ISmatch_source.xlsx"
source_file_list <- c("data/source/Set2_1_138_Short.XLS", "data/source/Set2_139_273_Short.XLS", "data/source/Set2_274_314_Short.XLS")

full_file_list <- c(reference_file_list, source_file_list)

# setting this to false
missing_file <- FALSE

for (file_path in full_file_list) {
  if (!fs::file_exists(file_path)) {
    # if a source file is missing, this will trigger
    # downloading source data from S3
    missing_file <- TRUE
  }
}

# if a file is missing pull source data from S3
if (missing_file) {
  source("R/GetSourceData.R")
} else {
  # if all files are downloaded, skip downloading data
  print("Source Data Downloaded")
}

####################################
# Process Measured Data
####################################


read_in_raw_data <- function(source_file_name, sheet_name, source_type) {
  # read in the sheet and skip the top 4 names
  df <- readxl::read_xls(file_name, sheet_name, skip = 4) %>%
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
  match_ist <- stringr::str_to_lower(match_list$processing_method_name)

  if (analyte_name %in% match_ist) {
    analyte_match <- "Match Found"
  } else {
    analyte_match <- "No Match Found"
    print(analyte_name)
    print("Match Not Found")
  }

  return(analyte_match)
}


#' A that takes care of processing all sheets in a source data file
#' @param file_name A path to where the file is located
process_raw_file <- function(file_name) {
  # initialize dataframes for adding files
  data_df <- dplyr::tibble()
  naming_df <- dplyr::tibble()

  # read in matching file for internal standards and
  # native analyte
  n_analyte_is_match <- readxl::read_excel(
    "data/source/Native_analyte_ISmatch_source.xlsx",
    sheet = "Sheet1"
  ) %>%
    janitor::clean_names()

  # loop through each sheet in the source excel file
  for (sheet in readxl::excel_sheets(file_name)) {
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

    # check if there is EPA in the sheet name
    if (stringr::str_detect(sheet, "_EPA")) {
      source_type <- "EPA"
      temp_data_df <- read_in_raw_data(file_name, sheet, source_type = "EPA")

      # check if there is _3M in the sheet name
    } else if (stringr::str_detect(sheet, "_3M")) {
      source_type <- "3M"
      temp_data_df <- read_in_raw_data(file_name, sheet, source_type = "3M")

      # check if there is an internal standard match
    } else if (sheet %in% n_analyte_is_match$internal_standard) {
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
      analyte_match = analyte_match
    )
    naming_df <- dplyr::bind_rows(
      naming_df,
      temp_naming_df
    )

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

# save the results out for review
readr::write_csv(combined_data_df, "data/processed/troubleshoot/raw_data_processing_output.csv")
readr::write_csv(combined_naming_df, "data/processed/troubleshoot/raw_data_processing_naming.csv")

####################################
# Split Data Into Separate Tables
####################################

####################################
# Create Analyte Table
####################################

# create_analyte_table <- function(df) {
temp_analyte_df <- combined_data_df %>%
  dplyr::filter(source_type == "native_analyte") %>%
  # filter down to analytes that have a match in the reference file
  dplyr::filter(analyte_match == "Match Found") %>%
  # filter down to cal values
  dplyr::filter(
    stringr::str_detect(stringr::str_to_lower(filename), "cal")
  ) %>%
  dplyr::mutate(
    # calculate the length of the analyte name to trim the number
    # off the end
    analyte_name_length = stringr::str_length(sheet_name),
    # remove the _# from the end of the analyte name
    analyte_name = stringr::str_sub(sheet_name, 0, analyte_name_length - 2),
    # capture the transition number
    transition_number = stringr::str_sub(sheet_name, -1),
    underscore_count = stringr::str_count(filename, "_")
  ) %>%
  # only interested in the first transition for an analyte
  dplyr::filter(transition_number == 1)

without_rep_number_df <- temp_analyte_df %>%
  dplyr::filter(underscore_count == 1) %>%
  dplyr::mutate(
    replicate_number = 1,
    split_filename = stringr::str_split_fixed(filename, "_", 2),
    calibration_level = as.integer(split_filename[, 2])
  ) %>%
  dplyr::select(
    source_file_name,
    source_type,
    sheet_name,
    filename,
    area,
    analyte_name_length,
    analyte_name,
    transition_number,
    replicate_number,
    calibration_level
  )

with_rep_number_df <- temp_analyte_df %>%
  dplyr::filter(underscore_count == 2) %>%
  dplyr::filter(!stringr::str_detect(filename, "rep")) %>%
  dplyr::mutate(
    split_filename = stringr::str_split_fixed(filename, "_", 3),
    replicate_number = as.integer(split_filename[, 2]),
    calibration_level = as.integer(split_filename[, 3])
  ) %>%
  dplyr::select(
    source_file_name,
    source_type,
    sheet_name,
    filename,
    area,
    analyte_name_length,
    analyte_name,
    transition_number,
    replicate_number,
    calibration_level
  )

# handle rep number in name

temp_analyte_rep_df <- temp_analyte_df %>%
  dplyr::filter(underscore_count == 2) %>%
  dplyr::filter(stringr::str_detect(filename, "rep")) %>%
  dplyr::mutate(
    split_filename = stringr::str_split_fixed(filename, "_", 3),
    replicate_number = as.integer(stringr::str_remove(split_filename[, 3], "rep")),
    calibration_level = as.integer(split_filename[, 2])
  ) %>%
  dplyr::select(
    source_file_name,
    source_type,
    sheet_name,
    filename,
    individual_native_analyte_peak_area = area,
    analyte_name_length,
    analyte_name,
    transition_number,
    replicate_number,
    calibration_level
  )

dplyr::bind_rows(
  without_rep_number_df,
  with_rep_number_df,
  temp_analyte_rep_df
) %>%
  # head()
  readr::write_csv("data/processed/source/source_data_individual_native_analyte.csv")

####################################
# Create Individual Standard Table
####################################

temp_ind_df <- combined_data_df %>%
  # filter down to internal_standard
  dplyr::filter(source_type == "internal_standard") %>%
  # filter down to cal levels
  dplyr::filter(
    stringr::str_detect(stringr::str_to_lower(filename), "cal")
  ) %>%
  dplyr::mutate(
    internal_standard = sheet_name,
    underscore_count = stringr::str_count(filename, "_")
  )

temp_ind_without_rep_df <- temp_ind_df %>%
  dplyr::filter(underscore_count == 1) %>%
  dplyr::mutate(
    replicate_number = 1,
    split_filename = stringr::str_split_fixed(filename, "_", 2),
    calibration_level = as.integer(split_filename[, 2])
  ) %>%
  dplyr::select(
    source_file_name,
    source_type,
    sheet_name,
    filename,
    area,
    internal_standard,
    replicate_number,
    calibration_level
  )

temp_ind_with_rep_df <- temp_ind_df %>%
  dplyr::filter(underscore_count == 2) %>%
  dplyr::filter(!stringr::str_detect(filename, "rep")) %>%
  dplyr::mutate(
    split_filename = stringr::str_split_fixed(filename, "_", 3),
    replicate_number = as.integer(split_filename[, 2]),
    calibration_level = as.integer(split_filename[, 3])
  ) %>%
  dplyr::select(
    source_file_name,
    source_type,
    sheet_name,
    filename,
    area,
    internal_standard,
    replicate_number,
    calibration_level
  )

temp_ind_rep_df <- temp_ind_df %>%
  dplyr::filter(underscore_count == 2) %>%
  dplyr::filter(stringr::str_detect(filename, "rep")) %>%
  dplyr::mutate(
    split_filename = stringr::str_split_fixed(filename, "_", 3),
    replicate_number = as.integer(stringr::str_remove(split_filename[, 3], "rep")),
    calibration_level = as.integer(split_filename[, 2])
  ) %>%
  dplyr::select(
    source_file_name,
    source_type,
    sheet_name,
    filename,
    internal_standard_analyte_peak_area = area,
    internal_standard,
    replicate_number,
    calibration_level
  )

dplyr::bind_rows(
  temp_ind_without_rep_df,
  temp_ind_with_rep_df,
  temp_ind_rep_df
) %>%
  readr::write_csv("data/processed/source/source_data_internal_standard.csv")