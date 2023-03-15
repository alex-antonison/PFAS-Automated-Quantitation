#' Calculate the calibration Curve
#' 
library(magrittr)

# source("R/build-calibration-curve/BuildCalibrationCurveInput.R")

calibration_curve_input_df <- arrow::read_parquet("data/processed/calibration-curve/calibration_curve_input.parquet")

remove_cal_level <- function(df, min_flag) {
  if (min_flag) {
    remove_val <- min(df$calibration_level)
    min_flag <- FALSE
  } else {
    remove_val <- max(df$calibration_level)
    min_flag <- TRUE
  }
  print(paste("Removing Calibration Range", remove_val))

  df <- df %>%
    dplyr::filter(calibration_level != remove_val)

  print("Removed cal range")

  return(list(df, min_flag, remove_val))
}


# build a list of analyte names
analyte_name_df <- calibration_curve_input_df %>%
  dplyr::distinct(
    individual_native_analyte_name
  )

calibration_curve_output_df <- dplyr::tibble()
calibration_curve_troublehsoot_df <- dplyr::tibble()

for (analyte in analyte_name_df$individual_native_analyte_name) {
  min_flag <- TRUE
  removed_calibration = ""

  base_df <- calibration_curve_input_df %>%
    dplyr::filter(individual_native_analyte_name == analyte)
  
  iteration = 1

  for (calibration_level in base_df$calibration_level) {
    cur_model <- lm(average_analyte_peak_area_ratio ~ analyte_concentration_ratio,
      data = base_df
    )

    r_squared <- summary(cur_model)$r.squared

    if (r_squared < 0.99) {
      

      print(r_squared)
      return_val <- remove_cal_level(base_df, min_flag)
      base_df <- return_val[[1]]
      min_flag <- return_val[[2]]
      remove_val <- return_val[[3]]
      removed_calibration <- paste(removed_calibration, remove_val, sep=":")
      
      cur_eval_df <- dplyr::tibble(
        individual_native_analyte_name = analyte,
        iteration_count = iteration,
        removed_calibration_level = remove_val,
        min_calibration_range = min(base_df$calibration_level),
        max_calibration_range = max(base_df$calibration_level),
        calibration_range = paste0(min(base_df$calibration_level), ":", max(base_df$calibration_level)),
        r_squared = r_squared,
        current_removed_calibration = stringr::str_sub(removed_calibration, start = 2)
        
      )
      
      calibration_curve_troublehsoot_df <- dplyr::bind_rows(
        calibration_curve_troublehsoot_df,
        cur_eval_df
      )
      
      iteration = iteration + 1
      
    } else {
      
      cf <- coef(cur_model)

      print("Successful R^2")
      print(paste0("R.Squared is ", r_squared))
      print(paste0("Cal range from ", min(base_df$calibration_level), ":", max(base_df$calibration_level)))

      cur_successful_df <- dplyr::tibble(
        individual_native_analyte_name = analyte,
        slope = cf[["analyte_concentration_ratio"]],
        intercept = cf[["(Intercept)"]],
        r_squared = r_squared,
        calibration_point = nrow(base_df),
        min_calibration_range = min(base_df$calibration_level),
        max_calibration_range = max(base_df$calibration_level),
        calibration_range = paste0(min(base_df$calibration_level), ":", max(base_df$calibration_level)),
        removed_calibrations = stringr::str_sub(removed_calibration, start = 2)
      )

      calibration_curve_output_df <- dplyr::bind_rows(
        cur_successful_df,
        calibration_curve_output_df
      )
      break
    }
  }
}


calibration_curve_output_df %>% 
  arrow::write_parquet(
    sink = "data/processed/calibration-curve/calibration_curve_output.parquet"
  ) %>% 
  readr::write_excel_csv("data/processed/calibration-curve/calibration_curve_output.csv")

calibration_curve_troublehsoot_df %>% 
  arrow::write_parquet(
    sink = "data/processed/calibration-curve/calibration_curve_troublehsoot.parquet"
  ) %>% 
  readr::write_excel_csv("data/processed/calibration-curve/calibration_curve_troublehsoot.csv")