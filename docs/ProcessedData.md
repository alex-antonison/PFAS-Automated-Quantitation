Processed Data
================
2023-02-14

``` r
analyte_concen_df <- arrow::read_parquet("../data/processed/analyte_concentrations.parquet")

head(analyte_concen_df)
```

    ## # A tibble: 6 × 3
    ##   calibration_level analyte_concentration cal_curve
    ##   <chr>             <chr>                     <dbl>
    ## 1 Cal_14_Sep2021    PFHxA                   107021.
    ## 2 Cal_14_Sep2021    PFHpA                   107021.
    ## 3 Cal_14_Sep2021    PFTrDA                  107021.
    ## 4 Cal_14_Sep2021    PFOA                    107021.
    ## 5 Cal_14_Sep2021    PFDA                    107021.
    ## 6 Cal_14_Sep2021    FOSA                    107021.
