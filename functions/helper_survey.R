# Purpose: survey design and descriptive helpers for NHANES analyses.
# Inputs: analysis-ready data with SDMVPSU, SDMVSTRA, WT_14YR.
# Outputs: survey design objects and weighted descriptive summaries.
# Dependencies: survey.

build_design <- function(df) {
  survey::svydesign(
    ids = ~SDMVPSU,
    strata = ~SDMVSTRA,
    weights = ~WT_14YR,
    nest = TRUE,
    data = df
  )
}

weighted_mean_se <- function(design, var) {
  out <- survey::svymean(stats::as.formula(paste0("~", var)), design, na.rm = TRUE)
  c(mean = as.numeric(stats::coef(out)[1]), se = as.numeric(survey::SE(out)[1]))
}

weighted_indicator_pct_se <- function(design, var, level) {
  d <- design$variables
  indicator <- as.numeric(as.character(d[[var]]) == level)
  tmp_name <- ".indicator_for_pct"
  d[[tmp_name]] <- indicator
  tmp_design <- build_design(d)
  out <- survey::svymean(stats::as.formula(paste0("~", tmp_name)), tmp_design, na.rm = TRUE)
  c(pct = as.numeric(stats::coef(out)[1]) * 100, se = as.numeric(survey::SE(out)[1]) * 100)
}

complete_case_data <- function(df, vars) {
  needed <- unique(c(vars, "Time", "event", "SDMVPSU", "SDMVSTRA", "WT_14YR"))
  d <- df[, needed, drop = FALSE]
  d[stats::complete.cases(d), , drop = FALSE]
}
