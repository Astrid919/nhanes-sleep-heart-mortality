# Purpose: run MICE and pooled survey-weighted Cox models.
# Inputs: data/processed/analysis_dataset.rds; global fast_test optional.
# Outputs: MI method/predictor tables, pooled MI Cox tables, mice object RDS.
# Dependencies: mice, survey, survival.

source(file.path("R", "00_setup.R"))

primary <- readRDS(file.path("data", "processed", "analysis_dataset.rds"))
models <- model_covariates()
m <- if (exists("fast_test", inherits = TRUE) && isTRUE(fast_test)) 5 else 50
maxit <- 10

mi_vars <- unique(c(
  "Sleeptime", "SleepClinical5", "Time", "event", "WT_14YR", "SDMVPSU", "SDMVSTRA",
  unlist(models, use.names = FALSE)
))
imp_data <- primary[, mi_vars, drop = FALSE]
imp_data$logTime <- log(pmax(imp_data$Time, 0.01))
imp_data <- ensure_factor_vars(imp_data, c(
  "Gender", "Race", "Education", "Marital", "Smoke", "PhysicalActivityAny",
  "AlcoholUse", "Hypertension", "Diabetes", "Stroke", "CVD", "SleepClinical5"
))

ini <- mice::mice(imp_data, maxit = 0, printFlag = FALSE)
method <- ini$method
pred <- ini$predictorMatrix
no_impute <- c("Sleeptime", "SleepClinical5", "Time", "logTime", "event", "WT_14YR", "SDMVPSU", "SDMVSTRA")
method[intersect(no_impute, names(method))] <- ""
for (v in names(method)) {
  if (method[[v]] == "") next
  if (is.factor(imp_data[[v]])) {
    method[[v]] <- if (nlevels(imp_data[[v]]) <= 2) "logreg" else "polyreg"
  } else {
    method[[v]] <- "pmm"
  }
}
pred[, "SleepClinical5"] <- 0
pred["SleepClinical5", ] <- 0
pred[intersect(no_impute, rownames(pred)), ] <- 0
diag(pred) <- 0

set.seed(20260626)
imp <- mice::mice(
  imp_data, m = m, maxit = maxit, method = method,
  predictorMatrix = pred, printFlag = TRUE, seed = 20260626
)
save_rds(imp, paste0("mice_primary_", m, "_imputations"))
write_table_all(data.frame(variable = names(method), method = unname(method)), "mice_methods")
write_table_all(as.data.frame(pred), "mice_predictor_matrix")

fit_mi <- function(exposure, covars, model_name) {
  coef_list <- list()
  vcov_list <- list()
  for (i in seq_len(imp$m)) {
    d <- mice::complete(imp, i)
    d$SleepClinical5 <- cut(
      d$Sleeptime, breaks = c(-Inf, 6, 7, 8, 9, Inf), right = FALSE,
      labels = c("<6 h", "6-<7 h", "7-<8 h", "8-<9 h", ">=9 h")
    )
    d <- ensure_factor_vars(d, c(
      "Gender", "Race", "Education", "Marital", "Smoke", "PhysicalActivityAny",
      "AlcoholUse", "Hypertension", "Diabetes", "Stroke", "CVD", "SleepClinical5"
    ))
    if ("SleepClinical5" %in% names(d)) {
      d$SleepClinical5 <- stats::relevel(droplevels(d$SleepClinical5), ref = "7-<8 h")
    }
    fit <- survey::svycoxph(
      stats::as.formula(paste("survival::Surv(Time, event) ~", paste(c(exposure, covars), collapse = " + "))),
      design = build_design(d)
    )
    coef_list[[i]] <- stats::coef(fit)
    vcov_list[[i]] <- stats::vcov(fit)
  }
  res <- pool_mi_terms(coef_list, vcov_list)
  res$model <- model_name
  res$n_analysis <- nrow(mice::complete(imp, 1))
  res$events <- sum(mice::complete(imp, 1)$event == 1)
  res
}

mi_linear <- data.table::rbindlist(lapply(c("Model_B_primary", "Model_C_clinical", "Model_D_conservative"), function(mn) {
  fit_mi("Sleeptime", models[[mn]], paste0("MI_", mn))
}), fill = TRUE)
mi_category <- data.table::rbindlist(lapply(c("Model_B_primary", "Model_C_clinical", "Model_D_conservative"), function(mn) {
  fit_mi("SleepClinical5", models[[mn]], paste0("MI_", mn))
}), fill = TRUE)

write_table_all(mi_linear, "mi_weighted_cox_linear_models")
write_table_all(mi_category, "mi_weighted_cox_category_models")
