s3 <- paws::s3()

#' A function to upload local files to s3
#' @param file_name A path to where the file is located
#' @param file_type Is it a source file or a processed file
upload_file_to_s3 <- function(file_path, file_name) {
  s3_path <- paste0(file_path, file_name)
  local_path <- paste0(file_path, file_name)
  s3$put_object(
    Body = local_path,
    Key = s3_path,
    Bucket = "univ-of-fl-data-collaboration"
  )
}

# do not upload non-data files to s3
exclude_files <- c(".DS_Store", ".gitignore", "README.md")

for (file_path in fs::dir_ls("data/source/")) {
  # extract file_name from path
  file_name <- fs::path_file(file_path)

  if (file_name %in% exclude_files) {
    print(paste0("Exclude: ", file_name))
  } else {
    print(paste0("Uploading: ", file_name, " to S3"))
    upload_file_to_s3("data/source/", file_name)
  }
}
