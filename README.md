# Interpretable and continuous AKI prediction in the intensive care

This is an implementation of an interpretable and continuous Long-Short term Memory (LSTM) network for the task of Acute Kidney Injury (AKI) prediction in ICU settings.

## Dependencies

- torch
- numpy
- sklearn
- pandas
- captum
- matplotlib
- seaborn

## Data

The [MIMIC III](https://mimic.physionet.org/) dataset was used. The SQL scripts used to extract features are provided in the [MIMIC code](https://github.com/MIT-LCP/mimic-code) repository. The expected data files are:

1. ```kdigo_stages_measured.csv``` containing time-series measurements of creatinine, urine output for the last six, 12 and 24 hours and the respective labels. 
2. ```icustay_detail-kdigo_stages_measured.csv``` containing non-temporal variables of patient demographics such as: age (numerical), gender (binary), ethnicity group (categorical) and type of admission (categorical).
3. ```labs-kdigo_stages_measured.csv``` containing time-series data of the laboratory tests.
4. ```vitals-kdigo_stages_measured.csv``` containing time-series data of the measurements of vital signs. 
5. ```vents-vasopressor-sedatives-kdigo_stages_measured.csv``` containing temporal information on whether mechanical ventilation, vasopressor or sedative medications were applied.

## Models

Continuous AKI prediction

- LSTM

Prediction 48 hours before the onset of AKI

- Logistic regression
- XGBoost
- Random forest
