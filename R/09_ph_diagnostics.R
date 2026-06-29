# Purpose: run approximate proportional hazards diagnostics.
# Inputs: data/processed/analysis_dataset.rds.
# Outputs: PH diagnostic tables and fitted unweighted Cox RDS objects.
# Dependencies: survival.

source(file.path("R", "00_setup.R"))

primary <- readRDS(file.path("data", "processed", "analysis_dataset.rds"))
covars <- model_covariates()[["Model_B_primary"]]

ph_one <- function(exposure, stem) {
  d <- complete_case_data(primary, c(exposure, covars))
  d <- ensure_factor_vars(d, c("Gender", "Race", "Education", "Marital", "Smoke", "PhysicalActivityAny", "AlcoholUse", "SleepClinical5"))
  if ("SleepClinical5" %in% names(d)) {
    d$SleepClinical5 <- stats::relevel(droplevels(d$SleepClinical5), ref = "7-<8 h")
  }
  fit <- survival::coxph(
    stats::as.formula(paste("survival::Surv(Time, event) ~", paste(c(exposure, covars), collapse = " + "))),
    data = d, x = TRUE
  )
  ph <- survival::cox.zph(fit)
  out <- as.data.frame(ph$table)
  out$term <- rownames(ph$table)
  rownames(out) <- NULL
  names(out) <- sub("^p$", "p_value", names(out))
  out$model <- stem
  out$n_complete <- nrow(d)
  out$events <- sum(d$event == 1)
  out$note <- "Approximate unweighted cox.zph diagnostic; survey design is not incorporated."
  write_table_all(out[, c("model", "term", setdiff(names(out), c("model", "term")))], paste0("ph_diagnostic_", stem))
  save_rds(list(fit = fit, ph = ph), paste0("ph_diagnostic_", stem, "_fit"))
  out
}

linear <- ph_one("Sleeptime", "model_b_linear")
category <- ph_one("SleepClinical5", "model_b_category")
summary <- rbind(
  data.frame(model = "Model_B_linear", n_complete = linear$n_complete[1], events = linear$events[1], global_p_value = linear$p_value[linear$term == "GLOBAL"]),
  data.frame(model = "Model_B_category", n_complete = category$n_complete[1], events = category$events[1], global_p_value = category$p_value[category$term == "GLOBAL"])
)
write_table_all(summary, "ph_diagnostic_model_b_summary")
