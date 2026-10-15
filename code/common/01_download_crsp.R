# =============================================================================
# code/common/01_download_crsp.R
# Download CRSP monthly data (returns, names history, delisting events),
# the CRSP equal-weighted market index, and the 1-month risk-free rate.
#
# Raw extracts are written to data/raw/ as .rds files.
# Run this script when the raw files are not already available locally.
#
# WRDS login:
# - username is entered in the R Console;
# - password is entered through RStudio's password prompt;
# - neither username nor password is stored in this repository.
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(DBI)
  library(dbplyr)
  library(RPostgres)
})

source("config/config.R")

# -------------------------------------------------------------------------
# WRDS connection
# -------------------------------------------------------------------------

wrds_user <- rstudioapi::showPrompt(
  title = "WRDS Login",
  message = "Enter your WRDS username:",
  default = ""
)

if (is.null(wrds_user) || trimws(wrds_user) == "") {
  stop("WRDS username cannot be blank.")
}

wrds <- DBI::dbConnect(
  RPostgres::Postgres(),
  host = "wrds-pgdata.wharton.upenn.edu",
  port = 9737,
  dbname = "wrds",
  sslmode = "require",
  user = wrds_user,
  password = rstudioapi::askForPassword("Enter your WRDS password")
)

message("Connected to WRDS.")


# -------------------------------------------------------------------------
# 1. Monthly stock file
# -------------------------------------------------------------------------
# ret = monthly total return including distributions.

msf <- tbl(wrds, in_schema("crsp", "msf")) |>
  filter(
    date >= !!SAMPLE_START,
    date <= !!SAMPLE_END
  ) |>
  select(
    permno,
    date,
    ret
  ) |>
  collect()

saveRDS(
  msf,
  file.path(PATH_RAW, "crsp_msf.rds")
)

message("msf rows: ", nrow(msf))

# -------------------------------------------------------------------------
# 2. Names history
# -------------------------------------------------------------------------
# Used to identify NYSE ordinary common stocks at each date.

msenames <- tbl(wrds, in_schema("crsp", "msenames")) |>
  select(
    permno,
    namedt,
    nameendt,
    shrcd,
    exchcd,
    comnam,
    ticker
  ) |>
  collect()

saveRDS(
  msenames,
  file.path(PATH_RAW, "crsp_msenames.rds")
)

message("msenames rows: ", nrow(msenames))

# -------------------------------------------------------------------------
# 3. Delisting events
# -------------------------------------------------------------------------

msedelist <- tbl(wrds, in_schema("crsp", "msedelist")) |>
  select(
    permno,
    dlstdt,
    dlret,
    dlstcd
  ) |>
  collect()

saveRDS(
  msedelist,
  file.path(PATH_RAW, "crsp_msedelist.rds")
)

message("msedelist rows: ", nrow(msedelist))

# -------------------------------------------------------------------------
# 4. CRSP equal-weighted market index
#    Decision 2, Alternative A
# -------------------------------------------------------------------------

msi <- tbl(wrds, in_schema("crsp", "msi")) |>
  filter(
    date >= !!SAMPLE_START,
    date <= !!SAMPLE_END
  ) |>
  select(
    date,
    ewretd
  ) |>
  collect()

saveRDS(
  msi,
  file.path(PATH_RAW, "crsp_msi.rds")
)

message("msi rows: ", nrow(msi))

# -------------------------------------------------------------------------
# 5. Risk-free rate
# -------------------------------------------------------------------------
# Fama-French monthly factors:
# rf is converted from percent to decimal.

rf <- tbl(wrds, in_schema("ff", "factors_monthly")) |>
  filter(
    date >= !!SAMPLE_START,
    date <= !!SAMPLE_END
  ) |>
  select(
    date,
    rf
  ) |>
  collect() |>
  mutate(
    rf = rf / 100
  )

saveRDS(
  rf,
  file.path(PATH_RAW, "ff_rf.rds")
)

message("rf rows: ", nrow(rf))

# -------------------------------------------------------------------------
# Disconnect
# -------------------------------------------------------------------------

DBI::dbDisconnect(wrds)

rm(wrds_user)

message("Download complete. Raw extracts written to ", PATH_RAW)
