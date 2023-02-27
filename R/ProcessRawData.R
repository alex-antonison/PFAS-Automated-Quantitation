library(magrittr)

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

process_raw_file <- function(file_name) {
  # initialize dataframes for adding files
  data_df <- dplyr::tibble()
  naming_df <- dplyr::tibble()

  # read in matching file for internal standards
  n_analyte_is_match <- readxl::read_excel(
    "data/source/Native_analyte_ISmatch_source.xlsx", "Sheet1"
  ) %>%
    janitor::clean_names()

  for (sheet in readxl::excel_sheets(file_name)) {
    analyte_match <- "NA"

    print(paste("Sheet Name is :", sheet))

    sheet_name_length <- stringr::str_length(sheet)

    last_two_char <- stringr::str_sub(sheet, -2)

    # ignore non-data sheets
    if (sheet %in% c("Component", "mdlCalcs")) next

    # check if there is EPA in the sheet name
    if (stringr::str_detect(sheet, "_EPA")) {
      print("EPA sheet")
      source_type <- "EPA"
      temp_data_df <- read_in_raw_data(file_name, sheet, source_type = "EPA")

      # check if there is _3M in the sheet name
    } else if (stringr::str_detect(sheet, "_3M")) {
      print("3M Sheet")
      source_type <- "3M"
      temp_data_df <- read_in_raw_data(file_name, sheet, source_type = "3M")


      # check if there is an internal standard match
    } else if (sheet %in% n_analyte_is_match$internal_standard) {
      print("Internal Standard")
      source_type <- "internal_standard"
      read_in_raw_data(file_name, sheet, source_type = "internal_standard")
      # check to see if there is a _1 or _2 in the name as
      # this indicates it is a native analyte
    } else if (last_two_char == "_1" || last_two_char == "_2") {
      source_type <- "native_analyte"
      temp_data_df <- read_in_raw_data(file_name, sheet, source_type = "native_analyte")

      str_length <- stringr::str_length(sheet)
      analyte_name <- stringr::str_sub(sheet, 0, str_length - 2)

      # checking to see if analyte name is found in document
      if (analyte_name %in% n_analyte_is_match$processing_method_name) {
        analyte_match <- "Match Found"
      } else {
        analyte_match <- "No Match Found"
      }
      
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

file_list <- c("data/source/Set2_1_138_Short.XLS", "data/source/Set2_139_273_Short.XLS", "data/source/Set2_274_314_Short.XLS")

combined_data_df <- dplyr::tibble()
combined_naming_df <- dplyr::tibble()

for (file_name in file_list) {
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
readr::write_csv(combined_data_df, "data/processed/raw_data_processing_output.csv")
readr::write_csv(combined_naming_df, "data/processed/raw_data_processing_naming.csv")
