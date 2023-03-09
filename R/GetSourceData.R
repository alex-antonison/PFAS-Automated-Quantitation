get_source_data <- function() {
  s3 <- paws::s3()

  bucket_name <- "univ-of-fl-data-collaboration"

  s3_obj_list <- s3$list_objects_v2(
    Bucket = bucket_name,
    Prefix = "data/source/"
  )

  for (obj in s3_obj_list$Contents) {
    object_key <- obj$Key
    local_file_path <- paste0(
      "data/source/",
      fs::path_split(object_key)[[1]][3]
    )
    print(local_file_path)
    s3$download_file(
      Bucket = bucket_name,
      Key = object_key,
      Filename = local_file_path
    )
  }
}

get_source_data()
