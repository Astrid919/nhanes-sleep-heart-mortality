# Purpose: run exploratory conventional Fine-Gray competing-risk sensitivity.
# Inputs: data/processed/analysis_dataset.rds.
# Outputs: outputs/tables/finegray_exploratory_model_b_category.* and RDS.
# Dependencies: survival.

source(file.path("R", "00_setup.R"))

primary <- readRDS(file.path("data", "processed", "analysis_dataset.rds"))
covars <- model_covariates()[["Model_B_primary"]]
d <- complete_case_data(primary, c("SleepClinical5", covars, "MORTSTAT", "SDMVPSU"))
d <- ensure_factor_vars(d, c("Gender", "Race", "Education", "Marital", "Smoke", "PhysicalActivityAny", "AlcoholUse", "SleepClinical5"))
d$SleepClinical5 <- stats::relevel(droplevels(d$SleepClinical5), ref = "7-<8 h")
d$cr_status <- factor(
  ifelse(d$event == 1, "heart", ifelse(d$MORTSTAT == 1, "other", "censor")),
  levels = c("censor", "heart", "other")
)
fg <- survival::finegray(
  stats::as.formula(paste("survival::Surv(Time, cr_status) ~", paste(c("SleepClinical5", covars, "SDMVPSU"), collapse = " + "))),
  data = d, etype = "heart"
)
fit <- survival::coxph(
  stats::as.formula(paste("survival::Surv(fgstart, fgstop, fgstatus) ~ SleepClinical5 +", paste(covars, collapse = " + "), "+ cluster(SDMVPSU)")),
  data = fg, weights = fgwt
)
res <- extract_model_table(fit)
res$n_complete <- nrow(d)
res$heart_events <- sum(d$cr_status == "heart")
res$competing_deaths <- sum(d$cr_status == "other")
res$note <- "Exploratory conventional Fine-Gray model with PSU-clustered robust standard errors; NHANES survey weights and strata are not fully incorporated."
write_table_all(res, "finegray_exploratory_model_b_category")
save_rds(list(fit = fit, result = res), "finegray_exploratory_model_b_category_fit")
