# Purpose: run Model B restricted cubic spline analyses and draw curves.
# Inputs: data/processed/analysis_dataset.rds.
# Outputs: RCS summary/curve tables, PNG/PDF figures, and fitted model RDS.
# Dependencies: survey, survival.

source(file.path("R", "00_setup.R"))

primary <- readRDS(file.path("data", "processed", "analysis_dataset.rds"))
covars <- model_covariates()[["Model_B_primary"]]

run_rcs <- function(knots, ref_sleep, stem) {
  d <- complete_case_data(primary, c("Sleeptime", covars))
  d <- ensure_factor_vars(d, c(
    "Gender", "Race", "Education", "Marital", "Smoke", "PhysicalActivityAny",
    "AlcoholUse"
  ))
  d$Sleep_rcs_lin <- d$Sleeptime
  basis <- make_rcs_basis(d$Sleeptime, knots)
  d <- cbind(d, basis)
  nl_terms <- names(basis)
  all_terms <- c("Sleep_rcs_lin", nl_terms)
  fit <- survey::svycoxph(
    stats::as.formula(paste("survival::Surv(Time, event) ~", paste(c(all_terms, covars), collapse = " + "))),
    design = build_design(d)
  )
  overall <- survey::regTermTest(fit, stats::as.formula(paste("~", paste(all_terms, collapse = " + "))))
  nonlinear <- survey::regTermTest(fit, stats::as.formula(paste("~", paste(nl_terms, collapse = " + "))))
  sleep_seq <- seq(min(d$Sleeptime, na.rm = TRUE), max(d$Sleeptime, na.rm = TRUE), length.out = 200)
  ref <- d[1, , drop = FALSE]
  for (v in names(ref)) {
    if (is.numeric(ref[[v]]) && !v %in% c("Time", "event", "SDMVPSU", "SDMVSTRA", "WT_14YR")) {
      ref[[v]] <- stats::median(d[[v]], na.rm = TRUE)
    }
    if (is.factor(ref[[v]])) {
      ref[[v]] <- factor(names(sort(table(d[[v]]), decreasing = TRUE))[1], levels = levels(d[[v]]))
    }
  }
  newdat <- ref[rep(1, length(sleep_seq)), , drop = FALSE]
  newdat$Sleeptime <- sleep_seq
  newdat$Sleep_rcs_lin <- sleep_seq
  newdat <- newdat[, !names(newdat) %in% nl_terms, drop = FALSE]
  newdat <- cbind(newdat, make_rcs_basis(newdat$Sleeptime, knots))
  refdat <- ref
  refdat$Sleeptime <- ref_sleep
  refdat$Sleep_rcs_lin <- ref_sleep
  refdat <- refdat[, !names(refdat) %in% nl_terms, drop = FALSE]
  refdat <- cbind(refdat, make_rcs_basis(refdat$Sleeptime, knots))
  mm_terms <- stats::delete.response(stats::terms(fit))
  x_new <- align_model_matrix(stats::model.matrix(mm_terms, newdat), names(stats::coef(fit)))
  x_ref <- align_model_matrix(stats::model.matrix(mm_terms, refdat), names(stats::coef(fit)))
  beta <- stats::coef(fit)
  vcv <- stats::vcov(fit)
  lp_new <- as.numeric(x_new %*% beta)
  lp_ref <- as.numeric(x_ref[1, , drop = FALSE] %*% beta)[1]
  x_diff <- sweep(x_new, 2, x_ref[1, ], FUN = "-")
  se_diff <- sqrt(rowSums((x_diff %*% vcv) * x_diff))
  curve <- data.frame(
    Sleeptime = sleep_seq,
    HR = exp(lp_new - lp_ref),
    lower_95 = exp((lp_new - lp_ref) - stats::qnorm(0.975) * se_diff),
    upper_95 = exp((lp_new - lp_ref) + stats::qnorm(0.975) * se_diff)
  )
  summary <- data.frame(
    model = "Model_B_primary", n_complete = nrow(d), events = sum(d$event == 1),
    ref_sleep = ref_sleep, knots = paste(knots, collapse = ","),
    p_overall_rcs = overall$p, p_nonlinear = nonlinear$p
  )
  write_table_all(summary, paste0(stem, "_summary"))
  write_table_all(curve, paste0(stem, "_curve"))
  save_rds(list(fit = fit, summary = summary, curve = curve), paste0(stem, "_fit"))
  draw <- function() {
    old <- par(mar = c(4.5, 4.8, 1.5, 1))
    on.exit(par(old), add = TRUE)
    plot(curve$Sleeptime, curve$HR, type = "n",
      xlab = "Sleep duration (hours/night)",
      ylab = "Hazard ratio for heart disease mortality",
      ylim = range(c(curve$lower_95, curve$upper_95, 1), finite = TRUE)
    )
    polygon(c(curve$Sleeptime, rev(curve$Sleeptime)),
      c(curve$lower_95, rev(curve$upper_95)),
      col = grDevices::adjustcolor("#6DAEDB", alpha.f = 0.25), border = NA
    )
    lines(curve$Sleeptime, curve$HR, col = "#1F5A85", lwd = 2.2)
    abline(h = 1, lty = 2, col = "#666666")
    mtext(sprintf("P overall = %s; P non-linearity = %s", format_p(overall$p), format_p(nonlinear$p)),
      side = 3, line = 0.2, adj = 0, cex = 0.9
    )
  }
  save_png_pdf(stem, draw)
}

run_rcs(c(4, 6, 7, 8, 9), 7, "rcs_model_b_5knot_ref7")
run_rcs(c(4, 6, 7, 9), 7, "rcs_model_b_4knot_ref7")
run_rcs(c(4, 6, 7, 8, 9), 7.5, "rcs_model_b_5knot_ref7_5")
