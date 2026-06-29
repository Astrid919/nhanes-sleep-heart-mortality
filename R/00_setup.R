# Purpose: configure paths, packages, random seed, and shared helpers.
# Inputs: optional global fast_test logical set by run_all.R.
# Outputs: directory objects and sourced helper functions.
# Dependencies: data.table, survey, survival, mice, writexl.

set.seed(20260626)
options(survey.lonely.psu = "adjust")

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(repo_root, "run_all.R"))) {
  stop("Run from the reproducible_plos_sleep_hd_mortality repository root.")
}

required_pkgs <- c("data.table", "survey", "survival", "mice", "writexl")
missing_pkgs <- required_pkgs[!vapply(required_pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_pkgs) > 0) {
  install.packages(missing_pkgs, repos = "https://cloud.r-project.org")
}

invisible(lapply(required_pkgs, require, character.only = TRUE))

source(file.path("functions", "helper_export.R"))
source(file.path("functions", "helper_cleaning.R"))
source(file.path("functions", "helper_survey.R"))
source(file.path("functions", "helper_models.R"))

ensure_dir(file.path("data", "processed"))
ensure_dir(file.path("outputs", "tables"))
ensure_dir(file.path("outputs", "figures"))
ensure_dir(file.path("outputs", "logs"))
