# Purpose: create Table 1 weighted baseline characteristics by sleep category.
# Inputs: data/processed/analysis_dataset.rds.
# Outputs: outputs/tables/table1_weighted_baseline_by_sleep.*.
# Dependencies: survey, data.table, writexl.

source(file.path("R", "00_setup.R"))

primary <- readRDS(file.path("data", "processed", "analysis_dataset.rds"))
group_levels <- c("<6 h", "6-<7 h", "7-<8 h", "8-<9 h", ">=9 h")
primary$SleepClinical5 <- factor(primary$SleepClinical5, levels = group_levels)

continuous <- c("Age", "PIR", "BMI", "BUN", "HGB", "HbA1c", "HDL", "SBP_analytic", "UA", "Creatinine")
continuous_labels <- c(
  Age = "Age, years", PIR = "Poverty-income ratio", BMI = "Body mass index",
  BUN = "Blood urea nitrogen", HGB = "Hemoglobin", HbA1c = "HbA1c",
  HDL = "HDL cholesterol", SBP_analytic = "Systolic blood pressure",
  UA = "Uric acid", Creatinine = "Creatinine"
)
categorical <- c(
  "Gender", "Race", "Education", "Smoke", "Marital", "PhysicalActivityAny",
  "AlcoholUse", "Hypertension", "Diabetes", "Stroke", "BaselineCHD"
)
level_labels <- list(
  Gender = c("1" = "Male", "2" = "Female"),
  Race = c("1" = "Mexican American", "2" = "Other Hispanic", "3" = "Non-Hispanic White",
           "4" = "Non-Hispanic Black", "5" = "Other race/multiracial"),
  Education = c("1" = "Less than 9th grade", "2" = "9-11th grade",
                "3" = "High school/GED", "4" = "Some college/AA degree",
                "5" = "College graduate or above"),
  Smoke = c("0" = "Current smoking: no", "1" = "Current smoking: yes"),
  Marital = c("0" = "Married/partnered: no", "1" = "Married/partnered: yes"),
  PhysicalActivityAny = c("0" = "Physical activity: no", "1" = "Physical activity: yes"),
  AlcoholUse = c("0" = "Alcohol use: no", "1" = "Alcohol use: yes"),
  Hypertension = c("0" = "Hypertension: no", "1" = "Hypertension: yes"),
  Diabetes = c("0" = "Diabetes: no", "1" = "Diabetes: yes"),
  Stroke = c("0" = "Stroke: no", "1" = "Stroke: yes"),
  BaselineCHD = c("0" = "Baseline coronary heart disease: no", "1" = "Baseline coronary heart disease: yes")
)

rows <- list()
n_row <- data.frame(Characteristic = "Unweighted n", Level = "", check.names = FALSE)
for (g in group_levels) {
  n_row[[g]] <- unname(table(primary$SleepClinical5)[g])
}
rows[[length(rows) + 1]] <- n_row

event_row <- data.frame(Characteristic = "Heart disease deaths, n", Level = "", check.names = FALSE)
for (g in group_levels) {
  event_row[[g]] <- sum(primary$event[primary$SleepClinical5 == g] == 1)
}
rows[[length(rows) + 1]] <- event_row

for (v in continuous) {
  row <- data.frame(Characteristic = continuous_labels[[v]], Level = "Mean (SE)", check.names = FALSE)
  for (g in group_levels) {
    est <- weighted_mean_se(subset(build_design(primary), SleepClinical5 == g), v)
    row[[g]] <- sprintf("%.2f (%.2f)", est["mean"], est["se"])
  }
  rows[[length(rows) + 1]] <- row
}

for (v in categorical) {
  levs <- levels(factor(primary[[v]]))
  for (i in seq_along(levs)) {
    lev <- levs[[i]]
    row <- data.frame(
      Characteristic = if (i == 1) v else "",
      Level = if (!is.null(level_labels[[v]]) && lev %in% names(level_labels[[v]])) level_labels[[v]][[lev]] else lev,
      check.names = FALSE
    )
    for (g in group_levels) {
      est <- weighted_indicator_pct_se(subset(build_design(primary), SleepClinical5 == g), v, lev)
      row[[g]] <- sprintf("%.1f%% (%.1f)", est["pct"], est["se"])
    }
    rows[[length(rows) + 1]] <- row
  }
}

table1 <- data.table::rbindlist(rows, fill = TRUE)
write_table_all(table1, "table1_weighted_baseline_by_sleep")
