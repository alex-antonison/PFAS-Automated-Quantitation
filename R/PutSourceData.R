library(paws)

s3 <- paws::s3()

upload_s3_file <- function(file_name, file_type) {
  file_path_for_s3 <- paste0("data/", file_type, "/", file_name)
  s3$put_object(
    Body = file_path_for_s3,
    Key = file_path_for_s3,
    Bucket = "univ-of-fl-data-collaboration"
  )
}

file_list <- c(
  "Extraction_Batches_source.xlsx",
  "IS_Mix_source.xlsx",
  "Sep2021Calibration_Curve_source.xlsx"
)

for (file_name in file_list) {
  print(file_name)
  upload_s3_file(file_name, "source")
}
