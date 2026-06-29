# Sleep Duration and Heart Disease Mortality Among US Adults

## Study Title

Sleep Duration and Heart Disease Mortality Among US Adults: A Survey-Weighted Analysis of NHANES 2005-2018 Linked Mortality Data

## Overview

This folder contains the cleaned public-source analysis data, R scripts, result tables, figures, and model objects needed to generate the manuscript result content. The analysis uses NHANES 2005-2006 through 2017-2018 linked to the NCHS public-use linked mortality files with follow-up through December 31, 2019.

The primary endpoint is heart disease mortality, defined as `UCOD_LEADING = 1`. Sleep duration is self-reported usual sleep duration, restricted to 3-11 h/night. Survey-weighted Cox models use `SDMVPSU`, `SDMVSTRA`, and `WT_14YR = WTMEC2YR / 7` or the equivalent precomputed `WT`.

## Repository Structure

- `data/processed/analysis_dataset.tsv`: cleaned public-source analysis table used by the default workflow.
- `data/README_data.md`: data provenance and placement instructions.
- `R/`: ordered analysis scripts.
- `functions/`: shared cleaning, survey, model, and export helpers.
- `run_all.R`: top-level runner.

## Data Sources

- NHANES public data: https://wwwn.cdc.gov/nchs/nhanes/
- NCHS public-use linked mortality files: https://www.cdc.gov/nchs/data-linkage/mortality-public.htm

This study uses public, de-identified NHANES data and public-use linked mortality files. No restricted-use mortality files or direct identifiers are included.

## Software Requirements

The manuscript reports R version 4.4.2 with:

- `data.table` 1.16.4
- `survey` 4.5
- `survival` 3.7.0
- `mice` 3.19.0
- `writexl` for XLSX export

## How To Reproduce

1. Clone or download this repository.
2. Open R in the repository root or call `setwd()` to this folder.
3. Install required packages or restore equivalent package versions.
4. Run:

```r
source("run_all.R")
```

The formal run uses `m = 50` MICE imputations and `maxit = 10`. For local development, set `fast_test <- TRUE` in `run_all.R` before sourcing `R/06_multiple_imputation.R`; formal reproduction should keep `fast_test <- FALSE`.

## Expected Runtime

Runtime depends mostly on multiple imputation and survey-weighted Cox fits. A formal 50-imputation run may take from tens of minutes to several hours on a desktop workstation.

## Main Outputs

- `outputs/tables/cox_continuous_results.*`
- `outputs/tables/cox_categorical_results.*`
- `outputs/tables/mi_weighted_cox_linear_models.*`
- `outputs/tables/mi_weighted_cox_category_models.*`
- `outputs/tables/rcs_model_b_5knot_ref7_summary.*`
- `outputs/figures/rcs_model_b_5knot_ref7.png`
Existing copied outputs are retained in `outputs/tables/` and `outputs/figures/` as generated manuscript result artifacts. Re-running `run_all.R` regenerates the result content from `data/processed/analysis_dataset.tsv`.

## Citation

Please cite the manuscript once published and cite NHANES/NCHS as the public data source.

## Contact

Jiayi Chen. See the manuscript title page for correspondence details.
