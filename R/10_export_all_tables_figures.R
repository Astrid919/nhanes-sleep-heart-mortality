# Purpose: create final manuscript figure assets and a manifest of generated outputs.
# Inputs: data/processed/analysis_dataset.rds plus outputs/tables and outputs/figures.
# Outputs: Figure 1 assets, PLOS-style TIFF figure copies, and generated_file_manifest.*.
# Dependencies: data.table, writexl.

source(file.path("R", "00_setup.R"))

primary <- readRDS(file.path("data", "processed", "analysis_dataset.rds"))

sleep_distribution <- as.data.frame(table(primary$Sleeptime), stringsAsFactors = FALSE)
names(sleep_distribution) <- c("Sleeptime", "n")
sleep_distribution$Sleeptime <- as.numeric(sleep_distribution$Sleeptime)
sleep_distribution <- sleep_distribution[order(sleep_distribution$Sleeptime), , drop = FALSE]
write_table_all(sleep_distribution, "sleep_duration_distribution_primary")

draw_sleep_distribution <- function() {
  old <- par(mar = c(4.5, 4.8, 1.5, 1))
  on.exit(par(old), add = TRUE)
  hist(primary$Sleeptime,
    breaks = seq(2.75, 11.25, by = 0.5),
    col = "#7BA7BC", border = "white",
    xlab = "Sleep duration (hours/night)",
    ylab = "Number of participants",
    main = ""
  )
  rug(sort(unique(primary$Sleeptime)), col = grDevices::adjustcolor("#333333", alpha.f = 0.45))
}
save_png_pdf("figure_1_sleep_duration_distribution", draw_sleep_distribution)

fig_dir <- file.path("outputs", "figures")
file.copy(
  file.path(fig_dir, "figure_1_sleep_duration_distribution.tiff"),
  file.path(fig_dir, "Figure_1.tiff"),
  overwrite = TRUE
)
if (file.exists(file.path(fig_dir, "rcs_model_b_5knot_ref7.tiff"))) {
  file.copy(
    file.path(fig_dir, "rcs_model_b_5knot_ref7.tiff"),
    file.path(fig_dir, "Figure_2.tiff"),
    overwrite = TRUE
  )
}

files <- list.files(c(file.path("outputs", "tables"), file.path("outputs", "figures")),
  recursive = TRUE, full.names = TRUE
)
manifest <- data.frame(
  relative_path = gsub(paste0("^", normalizePath(".", winslash = "/"), "/?"), "", normalizePath(files, winslash = "/", mustWork = FALSE)),
  extension = tools::file_ext(files),
  bytes = file.info(files)$size,
  stringsAsFactors = FALSE
)
write_table_all(manifest, "generated_file_manifest", file.path("outputs", "logs"))
