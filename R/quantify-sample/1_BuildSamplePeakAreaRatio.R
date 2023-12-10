#' Building the Peak Area Ratio Table with Samples
#'
#' This will use the the samples from the source data
#'
#' Input:
#'   Data:
#'     data/processed/source/sample_individual_native_analyte.parquet
#'     data/processed/source/sample_internal_standard.parquet
#'  Reference:
#'     data/processed/reference/native_analyte_internal_standard_mapping.parquet
#'
#' Output:
#'   data/processed/quantify-sample/peak_area_ratio.parquet

library(magrittr)

source("R/process-source-data/RefCreateMappingFiles.R")
source("R/build-calibration-curve/3_CalculateCalibrationCurve.R")
source("R/quantify-sample/ignore_list.R")

####################################
# Create Analyte Sample Table
####################################

batch_filename_error <- arrow::read_parquet(
  "data/processed/reference/batch_filename_error.parquet"
) %>%
  dplyr::mutate(
    # set flag to false since files filenames in the error config
    # need to be removed
    keep_filename_flag = FALSE
  )

combined_data_df <- arrow::read_parquet(
  "data/processed/source/full_raw_data.parquet"
) %>%
  # join dataframe that includes error filename
  dplyr::left_join(
    batch_filename_error,
    by = c("batch_number", "filename")
  ) %>%
  # for instances where filename is null since it wasn't in the error
  # config file, set it to TRUE
  # else, keep the current flag
  dplyr::mutate(
    keep_filename_flag = dplyr::if_else(is.na(keep_filename_flag),
      TRUE,
      keep_filename_flag
    )
  ) %>%
  dplyr::filter(keep_filename_flag)

combined_data_df %>%
  dplyr::filter(source_type == "native_analyte") %>%
  # filter down to analytes that have a match in the reference file
  dplyr::filter(analyte_match == "Match Found") %>%
  # filter down to only filenames that are not in the ignore list
  dplyr::filter(!(filename %in% ignore_catridge_list)) %>%
  dplyr::mutate(
    # flag for if a analyte is not NF
    analyte_detection_flag = dplyr::if_else((area == "NF"), FALSE, TRUE),
    # if area is not found, then set to NA
    area_prep = dplyr::if_else(analyte_detection_flag, area, NA),
    # rename to cartridge_number for joining later
    cartridge_number = readr::parse_number(filename),
    # convert peak area to numeric
    individual_native_analyte_peak_area = as.numeric(area_prep),
    # calculate analyte name
    analyte_name_length = stringr::str_length(sheet_name),
    individual_native_analyte_name = stringr::str_sub(sheet_name, 0, analyte_name_length - 2),
    # calculate transition number
    transition_number = stringr::str_sub(sheet_name, -1)
  ) %>%
  # filter to transition 1
  dplyr::filter(transition_number == 1) %>%
  dplyr::select(
    batch_number,
    individual_native_analyte_name,
    cartridge_number,
    analyte_detection_flag,
    individual_native_analyte_peak_area
  ) %>%
  arrow::write_parquet(
    sink = "data/processed/source/sample_individual_native_analyte.parquet"
  ) %>%
  readr::write_excel_csv(
    "data/processed/source/sample_individual_native_analyte.csv"
  )

####################################
# Create Internal Standard Sample Table
####################################

combined_data_df %>%
  dplyr::filter(source_type == "internal_standard") %>%
  # filter down to only filenames that are not in the ignore list
  dplyr::filter(!(filename %in% ignore_catridge_list)) %>%
  dplyr::mutate(
    internal_standard_name = sheet_name,
    # flag for if a analyte is not NF
    internal_standard_detection_flag = dplyr::if_else(
      (area == "NF"),
      FALSE,
      TRUE
    ),
    # if area is not found, then set to NA
    area_prep = dplyr::if_else(internal_standard_detection_flag, area, NA),
    # rename to cartridge_number for joining later
    cartridge_number = readr::parse_number(filename),
    # convert peak area to numeric
    internal_standard_peak_area = as.numeric(area_prep),
  ) %>%
  dplyr::select(
    batch_number,
    internal_standard_name,
    cartridge_number,
    internal_standard_detection_flag,
    internal_standard_peak_area
  ) %>%
  arrow::write_parquet(
    sink = "data/processed/source/sample_internal_standard.parquet"
  ) %>%
  readr::write_excel_csv(
    "data/processed/source/sample_internal_standard.csv"
  )

################### Start Calculation for Sample Peak Area Ratio

sample_native_analyte_df <- arrow::read_parquet(
  "data/processed/source/sample_individual_native_analyte.parquet"
)

sample_internal_standard_df <- arrow::read_parquet(
  "data/processed/source/sample_internal_standard.parquet"
)

native_analyte_internal_standard_mapping_df <- arrow::read_parquet(
  "data/processed/mapping/native_analyte_internal_standard_mapping.parquet"
)

sample_native_analyte_df %>%
  dplyr::left_join(
    native_analyte_internal_standard_mapping_df,
    by = "individual_native_analyte_name"
  ) %>%
  dplyr::left_join(
    sample_internal_standard_df,
    by = c("batch_number", "internal_standard_name", "cartridge_number")
  ) %>%
  dplyr::mutate(
    # calculate the peak area ratio
    peak_area_ratio = individual_native_analyte_peak_area / internal_standard_peak_area
  ) %>%
  arrow::write_parquet(
    sink = "data/processed/quantify-sample/peak_area_ratio.parquet"
  ) %>%
  readr::write_excel_csv(
    "data/processed/quantify-sample/peak_area_ratio.csv"
  )
