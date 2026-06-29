# Data README

## Data Sources

This analysis uses public, de-identified data from:

- NHANES public data: https://wwwn.cdc.gov/nchs/nhanes/
- NCHS public-use linked mortality files: https://www.cdc.gov/nchs/data-linkage/mortality-public.htm

The analysis combines NHANES cycles 2005-2006 through 2017-2018 and uses mortality follow-up through December 31, 2019.

## Included Processed Data

The default workflow starts from:

- `data/processed/analysis_dataset.tsv`

This file is a cleaned public-source analysis table derived from public NHANES and public-use linked mortality files. It includes harmonized sleep duration, mortality status, follow-up time, survey design variables, covariates, and a derived `PhysicalActivityAny` variable from public PAQ questionnaire items.

The default workflow does not automatically download or rebuild all NHANES XPT component files. It reproduces the manuscript result content from this cleaned minimal analysis dataset.

## Variable-Source Notes

- Heart disease mortality is defined as `UCOD_LEADING = 1`.
- `WT_14YR` is defined as the 2-year MEC weight divided by 7, or as the equivalent cleaned `WT` variable when present.
- Sleep duration is restricted to 3-11 h/night in the primary analytic sample.
- `BaselineCHD` is the analysis variable for baseline coronary heart disease. In the included cleaned table, the upstream MCQ160C-derived coronary-heart-disease indicator is stored as `CVD`; the workflow recodes this field to `BaselineCHD` before modeling.
- `SBP_analytic` is the systolic blood pressure covariate. In the included cleaned table, the upstream systolic BP measure derived from NHANES BPXSY1-BPXSY4 is stored in the processed `DBP` column. The workflow therefore sets `SBP_analytic = DBP` and does not use the processed `SBP` column for the manuscript systolic BP covariate.

## Raw Data Placement

Raw NHANES component files are not required for the default run because the processed public-source analysis table is included. If rebuilding from raw files outside this repository, place public NHANES component files and public-use mortality files under:

- `data/raw/nhanes/`
- `data/raw/mortality/`

Expected identifiers include `SEQN`, survey cycle/year, `WTMEC2YR`, `SDMVPSU`, `SDMVSTRA`, sleep questionnaire fields, covariates used in Models A-D, and public-use mortality fields including `MORTSTAT`, `PERMTH_EXM` or equivalent follow-up time, and `UCOD_LEADING`.

## Public Data And De-Identification

NHANES public files and public-use linked mortality files are de-identified public-use data. No restricted-use mortality files, direct identifiers, or private data are included in this reproducibility folder.
