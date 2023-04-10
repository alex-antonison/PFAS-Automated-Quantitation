get_source_data <- function() {
  s3 <- paws::s3()

  bucket_name <- "univ-of-fl-data-collaboration"

  s3_obj_list <- s3$list_objects_v2(
    Bucket = bucket_name,
    Prefix = "data/source/",
  )

  for (obj in s3_obj_list$Contents) {
    object_key <- obj$Key
    print(object_key)

    s3$download_file(
      Bucket = bucket_name,
      Key = object_key,
      Filename = object_key
    )
  }
}

get_source_data()
