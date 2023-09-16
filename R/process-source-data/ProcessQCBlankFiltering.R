library(magrittr)


readxl::read_excel("data/source/reference/QC_BlankFiltering_ngValues.xlsx") %>% 
  janitor::clean_names() %>% 
  dplyr::mutate(
    individual_native_analyte_name = compound_name,
    quality_control_sample_type = dplyr::case_when(
      qc_type == "Fresh" ~ "Fresh Water QC",
      qc_type == "Salt" ~ "Salt Water QC"
    )
  ) %>% 
  dplyr::select(
    individual_native_analyte_name,
    quality_control_sample_type,
    ng_to_filter_ng
  )  %>%
  readr::write_excel_csv(
    "data/processed/reference/quality_control_blank_filter_adjustment.csv"
  ) %>%
  arrow::write_parquet(
    sink = "data/processed/reference/quality_control_blank_filter_adjustment.parquet"
  )
  

