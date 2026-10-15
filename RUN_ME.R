# RUN_ME.R
# Main reproduction script for the final agreed replication.
#
# First-time use:
# 1. Open fm1973-replication.Rproj in RStudio.
# 2. Open this file.
# 3. Click Source.
#
# If the raw WRDS files are not available locally, the download script will
# ask for your WRDS username in the Console and your password in a secure
# RStudio password prompt. Login details are not stored in the repository.

source("code/common/00_setup.R")

required_raw <- here(
  PATH_RAW,
  c(
    "crsp_msf.rds",
    "crsp_msenames.rds",
    "crsp_msedelist.rds",
    "crsp_msi.rds",
    "ff_rf.rds"
  )
)

# Download licensed WRDS data only when the local raw files do not exist.
if (!all(file.exists(required_raw))) {
  source("code/common/01_download_crsp.R")
}

# Build the common processed panel.
source("code/common/02_build_panel.R")

# Reproduce both decision-point comparisons.
source("code/decision1/compare_decision1.R")
source("code/decision2/compare_decision2.R")

# Reproduce the agreed final Tables 1-3.
source("code/final/run_all.R")

# Render the concise comparison report when rmarkdown is available.
if (requireNamespace("rmarkdown", quietly = TRUE)) {
  rmarkdown::render(
    "report/comparison_with_fm.Rmd",
    quiet = TRUE
  )
}

message("Replication complete. Check output/tables/, logs/, and report/.")
