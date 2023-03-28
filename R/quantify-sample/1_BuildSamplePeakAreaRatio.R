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

source("R/process-source-data/ProcessRawData.R")
source("R/process-source-data/RefCreateMappingFiles.R")

sample_native_analyte_df <- arrow::read_parquet(
  "data/processed/source/sample_individual_native_analyte.parquet"
)


sample_internal_standard_df <- arrow::read_parquet(
  "data/processed/source/sample_internal_standard.parquet"
)

native_analyte_internal_standard_mapping_df <- arrow::read_parquet(
  "data/processed/reference/native_analyte_internal_standard_mapping.parquet"
)

sample_native_analyte_df %>%
  dplyr::left_join(
    native_analyte_internal_standard_mapping_df,
    by = "individual_native_analyte_name"
  ) %>%
  dplyr::left_join(
    sample_internal_standard_df,
    by = c("internal_standard_name", "cartridge_number", "batch_number")
  ) %>%
  dplyr::mutate(
    # calculate the peak area ratio
    peak_area_ratio = individual_native_analyte_peak_area / internal_standard_peak_area
  ) %>%
  arrow::write_parquet(
    sink = "data/processed/quantify-sample/peak_area_ratio.parquet"
  ) %>%
  as.data.frame() %>%
  xlsx::write.xlsx(
    "data/processed/quantify-sample/peak_area_ratio.xlsx",
    row.names = FALSE
  )
