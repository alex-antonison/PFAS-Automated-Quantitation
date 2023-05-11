# NOtes

## Updates to LogicFlow for Calibration Curve and Quantifying Sample

1. The error batch + filename lines up closely with changes made to the LogicFlow
2. (TODO) (Done) Remove Batch_number from Internal Standard Max Calibration and add Mix configuration
3. (TODO) (Done) Need to bring in extraction batch source file during initial data loading in order to understand what Mix was used for an internal standard for a given batch.
4. (TODO) (Done) Rename average_peak_area_ratio_calculation to average_peak_area_ratio_calculation_input
5. (TODO) (Logic Flow Done) Rename without calibration recovery table and add min and max average_peak_area_ratio for calibration_curve_output_with_recovery = calibration_curve_output_no_recovery
6. (TODO) (Logic Flow Done) Add a step in Quantifying Sample for removing bad filenames from source file
7. (TODO) (Logic Flow Done) IN step "Build Analyte Concentration Calculation Table" Need to update the calibration curve output to include necessary output columns
8. (TOD) ((Logic Flow Done) For final step in generating the analyte concentration, turn it into a single process and highlight that there will be two analyte concentration outputs, one where the non-recovery calibration curve input was used and the other where recovery calibration output was used.

## Blank Filtering Updates

1. (TODO) In blank filtering, rename analyte_concentration_calculation_input -> analyte_concentration_calculation_output with and without recovery.
2. (TODO) Call out that for the output of Analyte Concentration Calculation and Blank Filtering calculation there are separate tables for with and without recovery.
3. (TODO) Add to Calibration_Curve_Range_Category the category of "Not Found" when a analyte has NF from the source file

## QC Notes

Up to this point, we have calculated everything up to blank filtered samples

These will be the separated QC Salt and Fresh Water

QC for each Batch - triplicate of levels of QC

The QC samples are a composite of different samples (salt and fresh water)

Just to see look at different matrix effect - salt vs fresh water suppression

How efficient our internal standards are

FOr each batch a total of 9 QC samples

1. Take the average for the outputs of the 3 replicate samples - calculate the Relative Standard Deviation (RSD) Percentage
2. Compare the numbers we are generating (in ng) to what we knew we spiked in from the beginning.
3. native_analyte_in_QC_ng -> use this value to compare what we got out of the samples
4. Same recovery calculation

1. (TODO) Write pre-processing code for QC Check Source

Question: How to handle missing analyte_concentration_ng for QC samples within levels.