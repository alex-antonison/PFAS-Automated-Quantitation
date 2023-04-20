library(magrittr)

extraction_batch_source <- arrow::read_parquet(
  "data/processed/extraction_batch_source.parquet"
)

cur_df <- extraction_batch_source %>% 
  # filter down to blanks and QC
  dplyr::filter(stringr::str_detect(county, "QC"))