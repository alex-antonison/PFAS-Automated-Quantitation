Processed Data
================
2023-02-14

# Overview

The Extraction_Batches_source.xlsx, IS_Mix_source.xlsx, and
Sep2021Calibration_Curve_source.xlsx have been processed into individual
tables that have been optimized for working with programatically.

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

### Extraction_Batches_source.xlsx

For Extraction_Batches_source.xlsx, all of the excel tabs were combined
into a single file.

``` r
batch_source_df <- arrow::read_parquet("../data/processed/processed_extract_batch_source.parquet")

knitr::kable(head(batch_source_df))
```

| batch_number | county              | sample_id    | cartridge_number | internal_standard_used | full_bottle_mass | empty_bottle_mass | sample_mass_g | coordinates                    | notes |
|:-------------|:--------------------|:-------------|:-----------------|:-----------------------|-----------------:|------------------:|--------------:|:-------------------------------|:------|
| Batch_13     | Extraction Blank    | EB66         | 1                | aug102021              |            305.0 |              37.5 |         267.5 |                                | NA    |
| Batch_13     | Salt Water QC       | S7QCL1       | 2                | aug102021              |            300.7 |              38.1 |         262.6 |                                | NA    |
| Batch_13     | Brevard County      | BRE-2431-085 | 3                | aug102021              |            300.0 |              37.7 |         262.3 | 28°19’43.968”N 80°46’45.984”W  | NA    |
| Batch_13     | Hillsborough County | HIL-2447-099 | 4                | aug102021              |            287.8 |              38.1 |         249.7 | 28°0’46.764”N 82°21’11.7”W     | NA    |
| Batch_13     | Brevard County      | BRE-2429-083 | 5                | aug102021              |            317.8 |              40.3 |         277.5 | 28°13’42.996”N 80°45’37.98”W   | NA    |
| Batch_13     | Volusia County      | VOL-2477-060 | 6                | aug102021              |            314.8 |              38.1 |         276.7 | 28°56’3.9984”N 80°49’45.9984”W | NA    |

### IS_Mix_source.xlsx

This

``` r
is_mix_source <- arrow::read_parquet("../data/processed/is_mix_source.parquet")

knitr::kable(head(is_mix_source))
```

| sheet_name       | mix_name   | mix_label | IS_mix_ppb |
|:-----------------|:-----------|:----------|-----------:|
| IS-Mix_Oct282021 | MPFAC-24ES | M4PFBA    |   85.47593 |
| IS-Mix_Oct282021 | MPFAC-24ES | M5PFPeA   |   85.47593 |
| IS-Mix_Oct282021 | MPFAC-24ES | M5PFHxA   |   85.47593 |
| IS-Mix_Oct282021 | MPFAC-24ES | M4PFHpA   |   85.47593 |
| IS-Mix_Oct282021 | MPFAC-24ES | M8PFOA    |   85.47593 |
| IS-Mix_Oct282021 | MPFAC-24ES | M9PFNA    |   85.47593 |
