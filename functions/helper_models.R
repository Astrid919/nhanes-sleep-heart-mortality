# Purpose: Cox, MI pooling, spline, Fine-Gray, and PH diagnostic helpers.
# Inputs: analysis-ready data frames and model specifications.
# Outputs: model result data frames and fitted model objects.
# Dependencies: survey, survival.

extract_model_table <- function(fit) {
  beta <- stats::coef(fit)
  se <- sqrt(diag(stats::vcov(fit)))
  z <- beta / se
  p <- 2 * stats::pnorm(abs(z), lower.tail = FALSE)
  q <- stats::qnorm(0.975)
  data.frame(
    term = names(beta),
    beta = unname(beta),
    se = unname(se),
    z = unname(z),
    p_value = unname(p),
    HR = exp(unname(beta)),
    lower_95 = exp(unname(beta - q * se)),
    upper_95 = exp(unname(beta + q * se)),
    row.names = NULL,
    check.names = FALSE
  )
}

run_svycox <- function(df, exposure, covars, model_name) {
  d <- complete_case_data(df, c(exposure, covars))
  factor_vars <- c(
    "Gender", "Race", "Education", "Marital", "Smoke", "PhysicalActivityAny",
    "AlcoholUse", "Hypertension", "Diabetes", "Stroke", "BaselineCHD", "SleepClinical5"
  )
  d <- ensure_factor_vars(d, intersect(factor_vars, names(d)))
  if ("SleepClinical5" %in% names(d)) {
    d$SleepClinical5 <- stats::relevel(droplevels(d$SleepClinical5), ref = "7-<8 h")
  }
  fit <- survey::svycoxph(
    stats::as.formula(paste("survival::Surv(Time, event) ~", paste(c(exposure, covars), collapse = " + "))),
    design = build_design(d)
  )
  res <- extract_model_table(fit)
  res$model <- model_name
  res$n_complete <- nrow(d)
  res$events <- sum(d$event == 1)
  list(fit = fit, result = res, data = d)
}

pool_mi_terms <- function(coef_list, vcov_list) {
  terms <- Reduce(union, lapply(coef_list, names))
  m <- length(coef_list)
  qmat <- matrix(NA_real_, nrow = m, ncol = length(terms), dimnames = list(NULL, terms))
  umat <- matrix(NA_real_, nrow = m, ncol = length(terms), dimnames = list(NULL, terms))
  for (i in seq_len(m)) {
    nm <- names(coef_list[[i]])
    qmat[i, nm] <- coef_list[[i]]
    umat[i, nm] <- diag(vcov_list[[i]])[nm]
  }
  out <- lapply(terms, function(term) {
    q <- qmat[, term]
    u <- umat[, term]
    ok <- is.finite(q) & is.finite(u)
    q <- q[ok]
    u <- u[ok]
    mm <- length(q)
    qbar <- mean(q)
    ubar <- mean(u)
    b <- if (mm > 1) stats::var(q) else 0
    total <- ubar + (1 + 1 / mm) * b
    se <- sqrt(total)
    df <- if (b <= .Machine$double.eps) Inf else (mm - 1) * (1 + ubar / ((1 + 1 / mm) * b))^2
    crit <- if (is.finite(df)) stats::qt(0.975, df = df) else stats::qnorm(0.975)
    p <- if (is.finite(df)) 2 * stats::pt(abs(qbar / se), df = df, lower.tail = FALSE) else 2 * stats::pnorm(abs(qbar / se), lower.tail = FALSE)
    data.frame(
      term = term, beta = qbar, se = se, df = df, p_value = p,
      HR = exp(qbar), lower_95 = exp(qbar - crit * se),
      upper_95 = exp(qbar + crit * se), m_used = mm,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, out)
}

make_rcs_basis <- function(x, knots) {
  knots <- sort(as.numeric(knots))
  k <- length(knots)
  if (k < 3) stop("At least 3 knots are required.")
  tp3 <- function(z) pmax(z, 0)^3
  denom <- (knots[k] - knots[1])^2
  basis <- vapply(seq_len(k - 2), function(j) {
    (tp3(x - knots[j]) -
      tp3(x - knots[k - 1]) * (knots[k] - knots[j]) / (knots[k] - knots[k - 1]) +
      tp3(x - knots[k]) * (knots[k - 1] - knots[j]) / (knots[k] - knots[k - 1])) / denom
  }, numeric(length(x)))
  basis <- matrix(basis, nrow = length(x), ncol = k - 2)
  basis <- as.data.frame(basis)
  names(basis) <- paste0("Sleep_rcs_nl", seq_len(ncol(basis)))
  basis
}

align_model_matrix <- function(x, beta_names) {
  if ("(Intercept)" %in% colnames(x) && !("(Intercept)" %in% beta_names)) {
    x <- x[, setdiff(colnames(x), "(Intercept)"), drop = FALSE]
  }
  missing_cols <- setdiff(beta_names, colnames(x))
  if (length(missing_cols) > 0) {
    add_mat <- matrix(0, nrow = nrow(x), ncol = length(missing_cols))
    colnames(add_mat) <- missing_cols
    x <- cbind(x, add_mat)
  }
  x[, beta_names, drop = FALSE]
}
