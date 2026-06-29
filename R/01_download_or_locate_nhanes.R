# Purpose: document and locate public NHANES/NCHS inputs used by the workflow.
# Inputs: data/processed/analysis_dataset.tsv or user-supplied public raw files.
# Outputs: outputs/logs/data_location_check.csv/xlsx/tsv.
# Dependencies: data.table, writexl.

source(file.path("R", "00_setup.R"))

processed_path <- file.path("data", "processed", "analysis_dataset.tsv")
raw_files <- list.files(file.path("data", "raw"), recursive = TRUE, full.names = FALSE)

location_check <- data.frame(
  item = c(
    "processed_analysis_dataset",
    "raw_directory_file_count",
    "nhanes_public_data_url",
    "nchs_public_use_mortality_url"
  ),
  value = c(
    if (file.exists(processed_path)) processed_path else "missing",
    length(raw_files),
    "https://wwwn.cdc.gov/nchs/nhanes/",
    "https://www.cdc.gov/nchs/data-linkage/mortality-public.htm"
  ),
  required_for_default_run = c(TRUE, FALSE, FALSE, FALSE),
  note = c(
    "Default workflow starts from this cleaned public-source analysis table.",
    "Raw files are optional when the processed public-source table is present.",
    "Use this site to rebuild from component XPT files if starting from raw NHANES.",
    "Use this site for public-use linked mortality files through 2019."
  )
)

write_table_all(location_check, "data_location_check", file.path("outputs", "logs"))
if (!file.exists(processed_path)) {
  stop("Missing ", processed_path, ". See data/README_data.md for placement instructions.")
}
