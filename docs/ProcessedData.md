Processed Data
================
2023-02-14

# Overview

The
[Extraction_Batches_source.xlsx](../data/source/Extraction_Batches_source.xlsx),
[IS_Mix_source.xlsx](../data/source/IS_Mix_source.xlsx), and
[Sep2021Calibration_Curve_source.xlsx](../data/source/Sep2021Calibration_Curve_source.xlsx)
have been processed into individual tables that have been optimized for
working with programatically.

## Files

### Sep2021Calibration_Curve_source.xlsx

The Sep2021Calibration_Curve_source.xlsx was split into two tables since
the upper table was the native analyte concentrations and the lower
table was the isotopically-labeled standards concentrations.

``` r
analyte_concen_df <- arrow::read_parquet("../data/processed/analyte_concentrations.parquet")

knitr::kable(head(analyte_concen_df))
```

| calibration_level | analyte_concentration | cal_curve |
|:------------------|:----------------------|----------:|
| Cal_14_Sep2021    | PFHxA                 |  107020.6 |
| Cal_14_Sep2021    | PFHpA                 |  107020.6 |
| Cal_14_Sep2021    | PFTrDA                |  107020.6 |
| Cal_14_Sep2021    | PFOA                  |  107020.6 |
| Cal_14_Sep2021    | PFDA                  |  107020.6 |
| Cal_14_Sep2021    | FOSA                  |  107020.6 |

``` r
is_label_df <- arrow::read_parquet("../data/processed/is_label_source.parquet")

knitr::kable(head(is_label_df))
```

| calibration_level | isotopically_labeled_standard | cal_curve |
|:------------------|:------------------------------|----------:|
| Cal_14_Sep2021    | M4PFBA                        |  1897.879 |
| Cal_14_Sep2021    | M5PFPeA                       |  1897.879 |
| Cal_14_Sep2021    | M5PFHxA                       |  1897.879 |
| Cal_14_Sep2021    | M4PFHpA                       |  1897.879 |
| Cal_14_Sep2021    | M8PFOA                        |  1897.879 |
| Cal_14_Sep2021    | M9PFNA                        |  1897.879 |
