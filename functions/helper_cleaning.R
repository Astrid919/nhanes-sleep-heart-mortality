# Purpose: clean the processed public-source NHANES analysis table.
# Inputs: data frame read from data/processed/analysis_dataset.tsv.
# Outputs: analysis-ready data with weights, outcome, sleep groups, and recodes.
# Dependencies: data.table.

to_numeric <- function(df, vars) {
  vars <- intersect(vars, names(df))
  for (v in vars) {
    df[[v]] <- suppressWarnings(as.numeric(df[[v]]))
  }
  df
}

safe_binary <- function(x, yes = 1, no = 2, other_no = NULL) {
  x <- suppressWarnings(as.numeric(x))
  out <- rep(NA_real_, length(x))
  out[x == yes] <- 1
  out[x == no | x %in% other_no] <- 0
  out
}

ensure_factor_vars <- function(df, vars) {
  vars <- intersect(vars, names(df))
  for (v in vars) {
    df[[v]] <- factor(df[[v]])
  }
  df
}

add_sleep_group <- function(df, sleep_var = "Sleeptime") {
  df$SleepClinical5 <- cut(
    df[[sleep_var]],
    breaks = c(-Inf, 6, 7, 8, 9, Inf),
    right = FALSE,
    labels = c("<6 h", "6-<7 h", "7-<8 h", "8-<9 h", ">=9 h")
  )
  df
}

recode_analysis_vars <- function(df) {
  if ("Smoke" %in% names(df)) {
    df$Smoke <- safe_binary(df$Smoke, yes = 1, no = 2)
  }
  if ("Marital" %in% names(df)) {
    df$Marital <- ifelse(df$Marital == 1, 1,
      ifelse(df$Marital %in% c(2, 3, 4, 5, 6), 0, NA)
    )
  }
  if ("Diabetes" %in% names(df)) {
    df$Diabetes <- ifelse(df$Diabetes == 1, 1,
      ifelse(df$Diabetes %in% c(0, 2, 3), 0, NA)
    )
  }
  if ("Stroke" %in% names(df)) {
    df$Stroke <- safe_binary(df$Stroke, yes = 1, no = 2)
  }
  if ("MCQ160C" %in% names(df)) {
    df$BaselineCHD <- safe_binary(df$MCQ160C, yes = 1, no = 2, other_no = 0)
    attr(df$BaselineCHD, "source_note") <- "Baseline coronary heart disease derived from NHANES MCQ160C."
  } else if ("CVD" %in% names(df)) {
    df$BaselineCHD <- safe_binary(df$CVD, yes = 1, no = 2, other_no = 0)
    attr(df$BaselineCHD, "source_note") <- paste(
      "Baseline coronary heart disease derived from the cleaned table field CVD,",
      "which is the upstream MCQ160C coronary-heart-disease indicator in this processed analysis table."
    )
  }
  if ("BaselineCHD" %in% names(df)) {
    df$CVD <- df$BaselineCHD
  }
  if ("Hypertension" %in% names(df)) {
    df$Hypertension <- ifelse(df$Hypertension == 1, 1,
      ifelse(df$Hypertension == 0, 0, NA)
    )
  }
  if ("Education" %in% names(df)) {
    df$Education <- ifelse(df$Education %in% 1:5, df$Education, NA)
  }
  if ("Drink2" %in% names(df)) {
    df$AlcoholUse <- ifelse(df$Drink2 == 1, 1,
      ifelse(df$Drink2 == 2, 0, NA)
    )
  }
  if (!"PhysicalActivityAny" %in% names(df)) {
    df$PhysicalActivityAny <- NA_real_
  }
  if ("DBP" %in% names(df)) {
    df$SBP_analytic <- df$DBP
    attr(df$SBP_analytic, "source_note") <- paste(
      "Systolic blood pressure covariate. The included cleaned analysis table stores",
      "the upstream NHANES systolic BP measure derived from BPXSY1-BPXSY4 in the processed DBP column.",
      "The processed SBP column is not used for the systolic BP covariate."
    )
  }
  df
}

primary_eligibility <- function(df, sleep_low = 3, sleep_high = 11) {
  keep <- !is.na(df$Sleeptime) &
    !is.na(df$Time) &
    !is.na(df$WT_14YR) &
    !is.na(df$SDMVPSU) &
    !is.na(df$SDMVSTRA) &
    df$Sleeptime >= sleep_low &
    df$Sleeptime <= sleep_high
  df[keep, , drop = FALSE]
}

prepare_analysis_data <- function(df) {
  num_vars <- c(
    "SEQN", "Age", "PIR", "BMI", "BUN", "HGB", "HbA1c", "FPG", "HDL",
    "CRP", "TC", "TG", "LDL", "Sleeptime", "SII", "SIRI", "SBP", "DBP",
    "UA", "Creatinine", "MORTSTAT", "Time", "UCOD_LEADING", "WTMEC2YR",
    "WT", "SDMVPSU", "SDMVSTRA", "Gender", "Race", "Education", "Drink1",
    "Drink2", "Smoke", "Marital", "Hypertension", "Diabetes",
    "Dyslipidemia", "Stroke", "CVD", "MCQ160C", "BaselineCHD", "PhysicalActivityAny"
  )
  df <- to_numeric(df, num_vars)
  df$year <- as.character(df$year)
  df$WT_14YR <- if ("WT" %in% names(df)) df$WT else df$WTMEC2YR / 7
  df$event <- as.integer(!is.na(df$UCOD_LEADING) & df$UCOD_LEADING == 1)
  df <- recode_analysis_vars(df)
  df <- add_sleep_group(df)
  factor_vars <- c(
    "Gender", "Race", "Education", "Marital", "Smoke", "PhysicalActivityAny",
    "AlcoholUse", "Hypertension", "Diabetes", "Stroke", "BaselineCHD", "SleepClinical5"
  )
  ensure_factor_vars(df, factor_vars)
}

model_covariates <- function() {
  list(
    Model_A = c("Age", "Gender", "Race"),
    Model_B_primary = c(
      "Age", "Gender", "Race", "PIR", "Education", "Marital", "Smoke",
      "BMI", "PhysicalActivityAny", "AlcoholUse"
    ),
    Model_C_clinical = c(
      "Age", "Gender", "Race", "PIR", "Education", "Marital", "Smoke",
      "BMI", "PhysicalActivityAny", "AlcoholUse", "Hypertension",
      "Diabetes", "Stroke", "BaselineCHD"
    ),
    Model_D_conservative = c(
      "Age", "Gender", "Race", "PIR", "Education", "Marital", "Smoke",
      "BMI", "PhysicalActivityAny", "AlcoholUse", "Hypertension",
      "Diabetes", "Stroke", "BaselineCHD", "BUN", "HGB", "HbA1c", "HDL",
      "SBP_analytic", "UA", "Creatinine"
    )
  )
}
