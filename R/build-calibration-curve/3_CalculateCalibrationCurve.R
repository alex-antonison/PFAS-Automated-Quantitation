#' Calculate the calibration Curve
#'
#' This is done with the following calculation
#'
#' y = average_peak_area_ratio
#' x = analyte_concentration_rate
#'
#' lm(y ~ x)

# clear out environment
rm(list = ls())

library(magrittr)



source("R/build-calibration-curve/2_BuildCalibrationCurveInput.R")

calibration_curve_input_df <- arrow::read_parquet(
  "data/processed/calibration-curve/calibration_curve_input.parquet"
)

unique(calibration_curve_input_df$batch_number)

# clear out calibration curve troubleshoot from previous run
debug_file_list <- c(
  "data/processed/calibration-curve/temp_successful_calibration_curve.csv",
  "data/processed/calibration-curve/temp_recovery_calc.csv",
  "data/processed/calibration-curve/calibration_recovery_troubleshoot.csv",
  "data/processed/calibration-curve/calibration_curve_troublehsoot.csv"
)
for (file in debug_file_list) {
  if (fs::file_exists(file)) fs::file_delete(file)
}

#' This function takes care of initializing a debugging table with a header column
#' and once created, it will then continue to append rows to the file.
#' @param df The troubleshoot df to be stored to a csv
#' @param filename The path and name of the file to be saved out
build_trouble_shoot_file <- function(df, filename) {
  if (!fs::file_exists(filename)) {
    readr::write_csv(
      df,
      filename
    )
  } else {
    readr::write_csv(
      df,
      filename,
      append = TRUE
    )
  }
}

#' This function removes either the lowest or highest calibration level based on what
#' was was previously removed. It will start off with removing the lowest range.
#' @param df The dataframe included the calibration levels for a single analyte
#' @param min_flag This is used to indicate whether or not the lowest or highest calibration
#' level should be removed.
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

#' This function will iterate through the different calibration levels
#' when caluclating the calibration curve. If a calibration range
#' does not have an R^2 > 0.99, it will remove the upper or lower calibration
#' range and then re-fit the remaining calibration ranges.
#' @param df The calibration curve input dataframe
#' @param analyte_name The name of the analyte being processed
#' @param run_count Used for debugging purposes to understand how many iterations
#' the process has taken
#' @param removed_calibration_flag This is used in the main loop to determine if any calibration ranges
#' have been removed in the previous iteration and if so, it will need to continue until
#' no calibration ranges are removed.
calculate_calibration_curve <- function(df,
                                        analyte_name,
                                        run_count,
                                        removed_calibration_flag) {
  min_flag <- TRUE
  removed_calibration <- ""
  iteration <- 1
  calibration_curve_troublehsoot_df <- dplyr::tibble()
  batch_number <- unique(calibration_curve_input_df$batch_number)

  base_df <- df %>%
    dplyr::filter(individual_native_analyte_name == analyte_name)

  for (calibration_level in base_df$calibration_level) {
    # use R's built in linear model function
    cur_model <- lm(average_peak_area_ratio ~ analyte_concentration_ratio,
      data = base_df
    )

    # pull r.squared from R summary of model
    r_squared <- summary(cur_model)$r.squared

    if (r_squared < 0.99) {
      # set remove calibration flag to true to indicate an analyte
      # has had a calibration removed from it
      removed_calibration_flag <- TRUE
      print(r_squared)
      return_val <- remove_cal_level(base_df, min_flag)
      base_df <- return_val[[1]]
      min_flag <- return_val[[2]]
      remove_val <- return_val[[3]]
      removed_calibration <- paste(removed_calibration, remove_val, sep = ":")

      cur_eval_df <- dplyr::tibble(
        batch_number = batch_number,
        individual_native_analyte_name = analyte_name,
        iteration_count = iteration,
        removed_calibration_level = remove_val,
        min_calibration_range = min(base_df$calibration_level),
        max_calibration_range = max(base_df$calibration_level),
        calibration_range = paste0(min(base_df$calibration_level), ":", max(base_df$calibration_level)),
        r_squared = r_squared,
        current_removed_calibration = stringr::str_sub(removed_calibration, start = 2),
        run_count = run_count
      )

      # this will check to see if the file exists and if it doesn't,
      # create the file with headers. if it does exist, it will append
      build_trouble_shoot_file(
        cur_eval_df,
        "data/processed/calibration-curve/calibration_curve_troublehsoot.csv"
      )


      iteration <- iteration + 1
    } else {
      cf <- coef(cur_model)

      analyte_calibration_curve <- base_df %>%
        dplyr::mutate(
          individual_native_analyte_name = analyte_name,
          slope = cf[["analyte_concentration_ratio"]],
          y_intercept = cf[["(Intercept)"]],
          r_squared = r_squared,
          calibration_point = nrow(base_df),
          min_calibration_range = min(base_df$calibration_level),
          max_calibration_range = max(base_df$calibration_level),
          calibration_range = paste0(min(base_df$calibration_level), ":", max(base_df$calibration_level)),
          removed_calibrations = stringr::str_sub(removed_calibration, start = 2)
        )

      # debug_df <- analyte_calibration_curve
      # debug_df$run_count <- run_count
      # build_trouble_shoot_file(
      #   debug_df,
      #   "data/processed/calibration-curve/temp_successful_calibration_curve.csv"
      # )

      return(list(analyte_calibration_curve, removed_calibration_flag))
    }
  }
}

#' This function takes care of running the calibration curve function and takes the output
#' and calculates the recovery values for each calibration level. If a calibration level
#' has a 0.8 <= recovery value <= 1.2 it is successful, if not it fails and is removed
#' from the dataframe. This will require re-calculating the calibration curve and then doing
#' a new check for recovery values
#' @param input_df The calibration curve input dataframe
#' @param run_count Used for debugging purposes to understand how many iterations
#' the process has taken
#' @param removed_calibration_flag This is used in the main loop to determine if any calibration ranges
#' have been removed in the previous iteration and if so, it will need to continue until
#' no calibration ranges are removed.
run_calibration_curve <- function(input_df,
                                  run_count,
                                  removed_calibration_flag) {
  # build a list of analyte names
  analyte_name_df <- input_df %>%
    dplyr::distinct(
      individual_native_analyte_name
    )

  calc_cal_curve <- dplyr::tibble()

  for (analyte in analyte_name_df$individual_native_analyte_name) {
    print(paste0("================= Run Count", run_count, " =============="))
    print(analyte)
    calc_cal_curve_temp <- calculate_calibration_curve(
      input_df,
      analyte,
      run_count,
      removed_calibration_flag
    )

    # if the removed_calibration_flag comes back true
    # set the flag to TRUE
    # this will trigger subsequent iterations
    if (calc_cal_curve_temp[[2]]) {
      removed_calibration_flag <- calc_cal_curve_temp[[2]]
    }

    calc_cal_curve <- dplyr::bind_rows(
      calc_cal_curve,
      calc_cal_curve_temp[[1]]
    )
  }

  # calculate the recovery values and store in a temp dataframe to then
  # filter passing and failing values into different dataframes
  recovery_cal_curve_temp <- calc_cal_curve %>%
    dplyr::mutate(
      experimental_concentration_ratio = (average_peak_area_ratio - y_intercept) / slope,
      recovery = experimental_concentration_ratio / analyte_concentration_ratio
    )

  # build_trouble_shoot_file(
  #   recovery_cal_curve_temp,
  #   "data/processed/calibration-curve/temp_recovery_calc.csv"
  # )

  # filter down to only passing recovery values
  recovery_cal_curve_eval <- recovery_cal_curve_temp %>%
    dplyr::filter(
      recovery >= 0.8 & recovery <= 1.2
    )

  # filter down recovery failed recovery values for troubleshooting purposes
  recovery_cal_curve_troubleshoot <- recovery_cal_curve_temp %>%
    dplyr::filter(
      recovery < 0.8 | recovery > 1.2
    ) %>%
    dplyr::mutate(
      run_count = run_count
    )

  # if any values get removed because of out of bounds recovery values
  # need to set removed calibration_flag to true
  if (nrow(recovery_cal_curve_troubleshoot) > 0) {
    print("**************** Removed Recovery Values ********************")
    removed_calibration_flag <- TRUE

    build_trouble_shoot_file(
      recovery_cal_curve_troubleshoot,
      "data/processed/calibration-curve/calibration_recovery_troubleshoot.csv"
    )
  }

  return(list(recovery_cal_curve_eval, removed_calibration_flag))
}

#####################################################################################
#####################################################################################
# The code below will run until there are not calibration levels removed from either
# a R^2 < 0.99 or recovery values outside the acceptable range of 0.8 to 1.2
#####################################################################################
#####################################################################################



# build a list of batches
batch_df <- calibration_curve_input_df %>%
  dplyr::distinct(
    batch_number
  )

complete_cal_curve_output <- dplyr::tibble()

for (batch in batch_df$batch_number) {
  print(paste0("Running batch number ", batch))
  # initialize run values values
  run_count <- 0
  cur_df <- calibration_curve_input_df %>%
    # process one batch at a time
    dplyr::filter(
      batch_number == batch
    )

  # this loop will continue to run until no calibration levels are removed
  while (TRUE) {
    removed_calibration_flag <- FALSE
    run_count <- run_count + 1
    cur_list <- run_calibration_curve(
      cur_df,
      as.character(run_count),
      removed_calibration_flag
    )

    # If there were not removed calibrations in the previous run, leaving the removed_calibration_flag
    # set to FALSE, the run will end and it will save out the resulting dataframe.
    removed_calibration_flag <- cur_list[[2]]
    if (!removed_calibration_flag) {
      temp_cal_curve_df <- cur_list[[1]]

      complete_cal_curve_output <- dplyr::bind_rows(
        temp_cal_curve_df,
        complete_cal_curve_output
      )

      break
    } else {
      # reset dataframe to only include columns needed for
      # calibration curve calculation
      cur_df <- cur_list[[1]] %>%
        dplyr::select(
          batch_number,
          individual_native_analyte_name,
          internal_standard_name,
          calibration_level,
          average_peak_area_ratio,
          analyte_concentration_ratio
        )
    }
  }
  print(paste0("Batch ", batch, " complete."))
}

complete_cal_curve_output %>%
  arrow::write_parquet(
    sink = "data/processed/calibration-curve/calibration_curve_output.parquet"
  ) %>%
  readr::write_csv(
    "data/processed/calibration-curve/calibration_curve_output.csv"
  )
