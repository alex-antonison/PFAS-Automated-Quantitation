library(paws)

s3 <- paws::s3()

#' A function to upload local files to s3
#' @param file_name A path to where the file is located
#' @param file_type Is it a source file or a processed file
upload_s3_file <- function(file_name, file_type) {
  s3_path <- paste0("data/", file_type, "/", file_name)
  local_path <- paste0("inst/extdata/", file_type, "/", file_name)
  s3$put_object(
    Body = local_path,
    Key = s3_path,
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
