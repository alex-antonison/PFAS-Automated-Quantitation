Processed Data
================
2023-02-14

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
