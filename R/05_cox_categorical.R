# Purpose: run survey-weighted Cox models for clinical sleep categories.
# Inputs: data/processed/analysis_dataset.rds.
# Outputs: outputs/tables/cox_categorical_results.* and cox_categorical_fits.rds.
# Dependencies: survey, survival.

source(file.path("R", "00_setup.R"))

primary <- readRDS(file.path("data", "processed", "analysis_dataset.rds"))
models <- model_covariates()
fits <- lapply(names(models), function(m) run_svycox(primary, "SleepClinical5", models[[m]], m))
names(fits) <- names(models)
results <- data.table::rbindlist(lapply(fits, `[[`, "result"), fill = TRUE)
write_table_all(results, "cox_categorical_results")
save_rds(fits, "cox_categorical_fits")
