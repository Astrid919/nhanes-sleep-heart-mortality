# Purpose: install R packages needed for the reproducible workflow.
# Run manually before source("run_all.R") if required packages are missing.

required_pkgs <- c("data.table", "survey", "survival", "mice", "writexl")
missing_pkgs <- required_pkgs[!vapply(required_pkgs, requireNamespace, logical(1), quietly = TRUE)]

if (length(missing_pkgs) == 0) {
  message("All required packages are already installed.")
} else {
  install.packages(missing_pkgs, repos = "https://cloud.r-project.org")
}
