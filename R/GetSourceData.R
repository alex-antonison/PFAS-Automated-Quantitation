library(paws)
library(fs)

s3 <- paws::s3()

bucket_name <- "univ-of-fl-data-collaboration"

s3_obj_list <- s3$list_objects_v2(Bucket = bucket_name, Prefix = "data/source/")

for (obj in s3_obj_list$Contents) {
  file_name <- obj$Key
  print(file_name)
  s3$download_file(
    Bucket = bucket_name,
    Key = file_name,
    Filename = file_name
  )
}
