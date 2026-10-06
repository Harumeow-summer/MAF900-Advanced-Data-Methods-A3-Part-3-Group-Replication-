# =============================================================================
# code/common/02_build_panel.R
# Build the tidy stock-month panel used by every later stage.
# One row per security-month with:
#   permno  CRSP permanent security identifier
#   ym      integer year*12 + month (fast window arithmetic)
#   date    month-end date
#   ret     total monthly return incl. dividends and (where applicable) the
#           delisting return; NA when no valid return exists for the month
#   listed  TRUE when the security is an NYSE ordinary common share that
#           month (date-valid names history: exchcd = 1, shrcd 10 or 11)
# Writes data/processed/panel.rds and a data dictionary.
# =============================================================================

suppressPackageStartupMessages({ library(dplyr); library(tidyr) })
source("config/config.R")

msf       <- readRDS(file.path(PATH_RAW, "crsp_msf.rds"))
msenames  <- readRDS(file.path(PATH_RAW, "crsp_msenames.rds"))
msedelist <- readRDS(file.path(PATH_RAW, "crsp_msedelist.rds"))

# ---- 1. Clean returns ------------------------------------------------------
# CRSP missing-return codes (-66, -77, -88, -99 in some vintages) and any
# value <= -1 are not valid returns; set to NA. These NA months are exactly
# the "intermittent missing monthly returns" at stake in Decision Point 1.
msf <- msf |>
  mutate(ret = ifelse(!is.na(ret) & ret <= -1, NA_real_, ret),
         ym  = ym(date))

# ---- 2. Merge delisting returns -------------------------------------------
# FM do not mention delisting returns (documented implementation decision;
# see README). We incorporate them so a security's final month reflects the
# delisting outcome: compound when both ret and dlret exist, use dlret alone
# when the final-month ret is missing.
dl <- msedelist |>
  filter(!is.na(dlret), dlret > -1) |>
  mutate(ym = ym(dlstdt)) |>
  select(permno, ym, dlret)

panel <- msf |>
  left_join(dl, by = c("permno", "ym")) |>
  mutate(ret = case_when(
    !is.na(ret) & !is.na(dlret) ~ (1 + ret) * (1 + dlret) - 1,
    is.na(ret)  & !is.na(dlret) ~ dlret,
    TRUE                        ~ ret
  )) |>
  select(permno, ym, date, ret)

# ---- 3. Date-valid NYSE common-stock flag ----------------------------------
# A security-month is "listed" when the month-end date falls inside a names
# record with exchcd = 1 (NYSE) and shrcd in {10, 11} (ordinary common
# shares). This is the agreed translation of FM's "common stocks traded on
# the New York Stock Exchange"; it excludes ADRs, closed-end funds, REITs
# and when-issued trading.
nyse_common <- msenames |>
  filter(exchcd == 1, shrcd %in% c(10L, 11L)) |>
  mutate(nameendt = coalesce(nameendt, SAMPLE_END)) |>
  select(permno, namedt, nameendt)

panel <- panel |>
  left_join(nyse_common, by = "permno", relationship = "many-to-many") |>
  mutate(listed = !is.na(namedt) & date >= namedt & date <= nameendt) |>
  group_by(permno, ym, date, ret) |>
  summarise(listed = any(listed), .groups = "drop")

saveRDS(panel, file.path(PATH_PROC, "panel.rds"))

# ---- 4. Data dictionary ----------------------------------------------------
writeLines(c(
  "panel.rds — stock-month panel (one row per permno-month)",
  "permno : CRSP permanent security identifier (integer)",
  "ym     : integer year*12+month",
  "date   : CRSP month-end date",
  "ret    : total monthly return incl. dividends and delisting return; NA = no valid return",
  "listed : TRUE if NYSE ordinary common share (exchcd=1, shrcd 10/11) at that date",
  "",
  sprintf("Rows: %d  Securities: %d  Months: %s to %s",
          nrow(panel), dplyr::n_distinct(panel$permno),
          format(min(panel$date), "%Y-%m"), format(max(panel$date), "%Y-%m"))
), file.path(PATH_PROC, "panel_dictionary.txt"))

message("Panel built: ", nrow(panel), " rows, ",
        dplyr::n_distinct(panel$permno), " securities.")
