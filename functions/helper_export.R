# Purpose: shared table, figure, and object export helpers.
# Inputs: data frames, plots created by caller, model objects.
# Outputs: CSV/XLSX/TSV tables, PNG/PDF figures, RDS objects.
# Dependencies: data.table, writexl.

ensure_dir <- function(path) {
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE, showWarnings = FALSE)
  }
  invisible(path)
}

write_table_all <- function(x, stem, out_dir = file.path("outputs", "tables")) {
  ensure_dir(out_dir)
  x <- as.data.frame(x)
  data.table::fwrite(x, file.path(out_dir, paste0(stem, ".csv")), na = "NA")
  data.table::fwrite(x, file.path(out_dir, paste0(stem, ".tsv")), sep = "\t", na = "NA")
  if (requireNamespace("writexl", quietly = TRUE)) {
    writexl::write_xlsx(list(data = x), file.path(out_dir, paste0(stem, ".xlsx")))
  } else {
    warning("Package writexl is unavailable; XLSX export skipped for ", stem)
  }
  invisible(x)
}

save_rds <- function(x, stem, out_dir = file.path("outputs", "tables")) {
  ensure_dir(out_dir)
  saveRDS(x, file.path(out_dir, paste0(stem, ".rds")))
  invisible(x)
}

save_png_pdf <- function(stem, draw_fun,
                         out_dir = file.path("outputs", "figures"),
                         width_px = 1800, height_px = 1200, res = 200,
                         width_in = 7, height_in = 5) {
  ensure_dir(out_dir)
  png(file.path(out_dir, paste0(stem, ".png")),
    width = width_px, height = height_px, res = res
  )
  draw_fun()
  dev.off()
  tiff(file.path(out_dir, paste0(stem, ".tiff")),
    width = width_px, height = height_px, res = res,
    compression = "lzw"
  )
  draw_fun()
  dev.off()
  pdf(file.path(out_dir, paste0(stem, ".pdf")),
    width = width_in, height = height_in
  )
  draw_fun()
  dev.off()
  invisible(file.path(out_dir, paste0(stem, c(".png", ".tiff", ".pdf"))))
}

format_p <- function(p) {
  ifelse(is.na(p), NA_character_,
    ifelse(p < 0.001, "<0.001", sprintf("%.3f", p))
  )
}

format_hr_ci <- function(hr, low, high) {
  sprintf("%.2f (%.2f-%.2f)", hr, low, high)
}
