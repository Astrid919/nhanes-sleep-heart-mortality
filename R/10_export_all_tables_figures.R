# Purpose: create a manifest of generated manuscript result outputs.
# Inputs: outputs/tables and outputs/figures.
# Outputs: outputs/logs/generated_file_manifest.*.
# Dependencies: data.table, writexl.

source(file.path("R", "00_setup.R"))

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
