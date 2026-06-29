# Purpose: build the analysis-ready NHANES mortality data set.
# Inputs: data/processed/analysis_dataset.tsv.
# Outputs: data/processed/analysis_dataset.rds and outputs/tables/analysis_dataset_flow.*.
# Dependencies: data.table, survey.

source(file.path("R", "00_setup.R"))

input_path <- file.path("data", "processed", "analysis_dataset.tsv")
df0 <- as.data.frame(data.table::fread(input_path, na.strings = c("NA", "")))
df <- prepare_analysis_data(df0)
primary <- primary_eligibility(df, 3, 11)

flow <- data.frame(
  step = c(
    "Rows in processed public-source table",
    "Available sleep duration",
    "Available sleep/follow-up/survey design",
    "Primary sleep range 3-11 h",
    "Heart disease deaths in primary sample"
  ),
  n = c(
    nrow(df),
    sum(!is.na(df$Sleeptime)),
    sum(!is.na(df$Sleeptime) & !is.na(df$Time) & !is.na(df$WT_14YR) &
      !is.na(df$SDMVPSU) & !is.na(df$SDMVSTRA)),
    nrow(primary),
    sum(primary$event == 1)
  )
)

saveRDS(primary, file.path("data", "processed", "analysis_dataset.rds"))
write_table_all(flow, "analysis_dataset_flow")

models <- model_covariates()
model_counts <- data.table::rbindlist(lapply(names(models), function(m) {
  d <- complete_case_data(primary, c("Sleeptime", models[[m]]))
  data.frame(
    model = m,
    n_complete = nrow(d),
    events = sum(d$event == 1),
    retained_percent = 100 * nrow(d) / nrow(primary)
  )
}))
write_table_all(model_counts, "model_complete_case_counts")
