# Source File Descriptions

## Large Scale Florida Surface Water Sampling

### Extraction_Batches_source.xlsx

This file contains all 13 extraction batches for this project. Each tab represents one of the 13 extraction batches. The relevant information from this file for sample quantitation will be the ‘Sample Mass’ (column G) and the ‘Internal Standard Used’ (column D). The internal standard used will correspond to the matching tab in the IS_Mix_source.xlsx file. 
For sample identification, ‘Cartridge Number’ (column C) will be matched to the sample file names from the raw data so the correct ‘Sample ID’ (column B) and ‘GPS Coordinates’ (column H) can be paired with the correct samples.
In the ‘GPS Coordinates’ column, field blanks were not given coordinates; instead they have the name of the corresponding counties they came from. Extraction blanks and QC samples were also not given coordinates; instead ‘NA’ was entered. Some of the coordinates are labeled ‘missing’. I am working on finding these missing coordinates and will update you if any of them are found. 

### IS_Mix_source.xlsx

This file contains the concentrations of each of our isotopically-labeled standards. Each tab represents an internal standard mix. Throughout this project, three of these mixes were used: (1)‘nov232020’ (2)‘March012021’ and (3)‘aug102021’. These are the first three tabs in this file. The Extraction_Batches_source.xlsx file specifies which internal standard corresponds to which batch (Batch 10 switches after row 145 in the excel file). The relevant information from this file for sample quantitation will be the name of the isotopically-labeled standard (column A, starting in row33) and the corresponding concentrations (column G, starting in row33).

### Sep2021Calibration_Curve_source.xlsx

This file contains the concentrations of native analytes and isotopically-labeled standards spiked in to each of the 14 levels of the calibration curve used in this experiment. Each tab represents one of the 14 solutions of the calibration curve, and one tab ‘Final_CalCurve_ppt_Sep2021’ contains all of the concentrations combined into two tables. The upper table represents the native analyte concentrations in each of the 14 calibration curve solutions. The lower table represents the isotopically-labeled standards concentrations in each of the 14 calibration solutions.
