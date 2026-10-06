# =============================================================================
# code/common/01_download_crsp.R
# Download CRSP monthly data (returns, names history, delisting events),
# the CRSP equal-weighted market index, and the 1-month T-bill rate.
# Writes raw extracts to data/raw/ as .rds. Run once; everything downstream
# reads from disk, so the replication does not depend on live WRDS access.
# =============================================================================
# Connection follows the MAF900 guide "Access WRDS data from RStudio":
# credentials live in a Postgres password file, NOT in code and NOT typed
# at a prompt, so this script runs non-interactively and the repository
# never contains a password.
#
#   Windows : create C:\Users\<USERNAME>\AppData\Roaming\postgresql\pgpass.conf
#   macOS   : create ~/.pgpass  then  chmod 600 ~/.pgpass
#   Both contain one line:
#     wrds-pgdata.wharton.upenn.edu:9737:wrds:wrds_username:wrds_password
#
# Your WRDS username also goes in config/wrds_credentials.R (git-ignored),
# copied from config/wrds_credentials_template.R.
#
# Note on CRSP formats: this script uses the legacy (SIZ) monthly tables
# crsp.msf / crsp.msenames / crsp.msedelist / crsp.msi, which WRDS continues
# to provide and which keep the variable names used below. If your
# subscription exposes only the CIZ ("v2") files, the equivalents are
# crsp.msf_v2 (mthret includes delisting returns) and crsp.stkshares /
# securitynames for the names history; adjust the queries and skip the
# delisting merge in 02_build_panel.R. Record whichever format you used in
# the README.

suppressPackageStartupMessages({
  library(tidyverse)
  library(DBI)
  library(dbplyr)
  library(RPostgres)
})
source("config/config.R")
source("config/wrds_credentials.R")

wrds <- dbConnect(Postgres(),
                  host    = "wrds-pgdata.wharton.upenn.edu",
                  port    = 9737,
                  dbname  = "wrds",
                  sslmode = "require",
                  user    = WRDS_USER)
# Password is read automatically from pgpass.conf / ~/.pgpass (see header).

# ---- 1. Monthly stock file (returns) --------------------------------------
# ret: total monthly return including dividends, adjusted for splits —
# matches FM's return definition. CRSP codes missing/invalid returns as NA
# or special codes < -1; both are treated as missing downstream.
msf <- tbl(wrds, in_schema("crsp", "msf")) |>
  filter(date >= !!SAMPLE_START, date <= !!SAMPLE_END) |>
  select(permno, date, ret) |>
  collect()
saveRDS(msf, file.path(PATH_RAW, "crsp_msf.rds"))
message("msf rows: ", nrow(msf))

# ---- 2. Names history (date-valid exchange and share type) -----------------
# Used to identify NYSE-listed ordinary common shares AT EACH DATE
# (exchcd = 1, shrcd in 10/11), avoiding look-ahead from current listings.
msenames <- tbl(wrds, in_schema("crsp", "msenames")) |>
  select(permno, namedt, nameendt, shrcd, exchcd, comnam, ticker) |>
  collect()
saveRDS(msenames, file.path(PATH_RAW, "crsp_msenames.rds"))
message("msenames rows: ", nrow(msenames))

# ---- 3. Delisting events ---------------------------------------------------
msedelist <- tbl(wrds, in_schema("crsp", "msedelist")) |>
  select(permno, dlstdt, dlret, dlstcd) |>
  collect()
saveRDS(msedelist, file.path(PATH_RAW, "crsp_msedelist.rds"))
message("msedelist rows: ", nrow(msedelist))

# ---- 4. CRSP equal-weighted market index (Decision 2, Alternative A) -------
msi <- tbl(wrds, in_schema("crsp", "msi")) |>
  filter(date >= !!SAMPLE_START, date <= !!SAMPLE_END) |>
  select(date, ewretd) |>
  collect()
saveRDS(msi, file.path(PATH_RAW, "crsp_msi.rds"))
message("msi rows: ", nrow(msi))

# ---- 5. Riskless rate: 1-month T-bill --------------------------------------
# Fama-French monthly factors: rf is the 1-month T-bill return in PERCENT
# per month; converted to decimal here so all series share units.
# Series begins 1926-07; the Table 3 intercept test only needs 1935-01
# onwards, so coverage is complete for every statistic we report.
rf <- tbl(wrds, in_schema("ff", "factors_monthly")) |>
  filter(date >= !!SAMPLE_START, date <= !!SAMPLE_END) |>
  select(date, rf) |>
  collect() |>
  mutate(rf = rf / 100)
saveRDS(rf, file.path(PATH_RAW, "ff_rf.rds"))
message("rf rows: ", nrow(rf))

dbDisconnect(wrds)
message("Download complete. Raw extracts written to ", PATH_RAW)
