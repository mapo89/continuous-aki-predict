# Interpretable and continuous AKI prediction in the intensive care

This is an implementation of an interpretable and continuous Long-Short term Memory (LSTM) network for the task of Acute Kidney Injury (AKI) prediction in ICU settings.

## Running

The LSTM model can be run via the `LSTM.ipynb`; the other baseline models can be run using the `LR_XGB_RF.ipynb` notebook.

To run the models some preliminary steps are needed to set-up the dataset and extract the data (see Section *Data* below).

## Dependencies

- torch
- numpy
- sklearn
- pandas
- captum
- matplotlib
- seaborn

## Data

The [MIMIC III](https://mimic.mit.edu/docs/iii/) dataset was used. The expected data files are:

1. ```kdigo_stages_measured.csv``` containing time-series measurements of creatinine, urine output for the last six, 12 and 24 hours and the respective labels. 
2. ```icustay_detail-kdigo_stages_measured.csv``` containing non-temporal variables of patient demographics such as: age (numerical), gender (binary), ethnicity group (categorical) and type of admission (categorical).
3. ```labs-kdigo_stages_measured.csv``` containing time-series data of the laboratory tests.
4. ```vitals-kdigo_stages_measured.csv``` containing time-series data of the measurements of vital signs. 
5. ```vents-vasopressor-sedatives-kdigo_stages_measured.csv``` containing temporal information on whether mechanical ventilation, vasopressor or sedative medications were applied.

To generate such data files some preliminary step are needed:

1. Set-up [MIMIC III](https://mimic.mit.edu/docs/iii/)
2. Run the following SQL scripts from the [MIMIC code](https://github.com/MIT-LCP/mimic-code) repository:
	- `mimic-iii/concepts/echo-data.sql`
	- `mimic-iii/concepts/demographics/icustay_detail.sql`
	- `mimic-iii/concepts/durations/weight-durations.sql`
	- `mimic-iii/concepts/durations/vasopressor-durations.sql`
	- `mimic-iii/concepts/durations/ventilation-durations.sql`
	- `mimic-iii/concepts/fluid-balance/urine-output.sql`
	- `mimic-iii/concepts/organfailure/kdigo-creatinine.sql`
	- `mimic-iii/concepts/organfailure/kdigo-stages-48hr.sql`
	- `mimic-iii/concepts/organfailure/kdigo-stages-7day.sql`
	- `mimic-iii/concepts/organfailure/kdigo-stages.sql`
	- `mimic-iii/concepts/organfailure/kdigo-uo.sql`
3. Run the SQL scripts in the [`sql`](sql/) folder. The `extract_data.sql` should be run after all the other scripts. These scripts builds on and extends the scripts from the MIMIC code repository mentioned at point 2.

## Models

Continuous AKI prediction

- LSTM

Prediction 48 hours before the onset of AKI

- Logistic regression
- XGBoost
- Random forest

## Cite

If you use our code in your own work please cite our paper: [Interpretable and Continuous Prediction of Acute Kidney Injury in the Intensive Care](https://doi.org/10.3233/shti210129).

Bibtex:

    @inproceedings{Vagliano:2021,
         author = {Vagliano, Iacopo and Lvova, Oleksandra and Schut, Martijn C},
         title = {Interpretable and Continuous Prediction of Acute Kidney Injury in the Intensive Care},
         booktitle = {Public Health and Informatics},
         series = {Studies in health technology and informatics},
         pages = {103—107},
         DOI = {10.3233/shti210129},
	     volume = {281},
	     month = {May},
	     year = {2021},
         URL = {https://doi.org/10.3233/SHTI210129},
         ISSN = {0926-9630},
    }
