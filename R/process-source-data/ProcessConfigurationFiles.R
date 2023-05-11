library(magrittr)

readxl::read_excel(
  "data/source/reference/batch_filename_error.xlsx"
  ) %>% 
  janitor::clean_names() %>% 
  readr::write_excel_csv(
    "data/processed/reference/batch_filename_error.csv"
  ) %>% 
  arrow::write_parquet(
    sink = "data/processed/reference/batch_filename_error.parquet"
  )

readxl::read_excel(
  "data/source/reference/internal_standard_max_calibration_level.xlsx"
) %>% 
  janitor::clean_names() %>% 
  readr::write_excel_csv(
    "data/processed/reference/internal_standard_max_calibration_level.csv"
  ) %>%
  arrow::write_parquet(
    sink = "data/processed/reference/internal_standard_max_calibration_level.parquet"
  )