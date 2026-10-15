# code/final/run_all.R
# Reproduce the group's agreed Tables 1-3.
#
# Final decisions:
#   Decision 1 = A (strict valid-return rule)
#   Decision 2 = B (reconstructed NYSE equal-weighted market proxy)
#
# This script uses code/common/ plus copies of the agreed rules in code/final/.
# It does not source either alternative-development folder.

source("code/common/00_setup.R")
source("code/common/04_functions_fm.R")
source("code/final/01_agreed_eligibility.R")
source("code/final/02_agreed_market_proxy.R")

panel <- read_rds(
  here(PATH_PROC, "panel.rds")
)

eligibility <- eligibility_final(
  panel,
  PERIODS
)

market <- market_proxy_final(
  panel
)

# -------------------------------------------------------------------------
# TABLE 1
# -------------------------------------------------------------------------

table1 <- eligibility %>%
  select(
    period,
    n_available,
    n_eligible
  )

write_csv(
  table1,
  here(PATH_TAB, "table1_final.csv")
)

# -------------------------------------------------------------------------
# TABLE 2
# -------------------------------------------------------------------------

period_results <- list()

for (p in 1:9) {

  current_period <- PERIODS[PERIODS$period == p, ]
  eligible_permnos <- eligibility$eligible[[p]]

  period_panel <- panel %>%
    filter(permno %in% eligible_permnos)

  formation_betas <- estimate_betas(
    period_panel,
    market,
    ym(current_period$form_start),
    ym(current_period$form_end),
    min_n = 48L
  )

  memberships <- assign_portfolios(
    formation_betas %>% select(permno, beta),
    N_PORTFOLIOS
  ) %>%
    select(permno, pf)

  estimation_betas <- estimate_betas(
    period_panel,
    market,
    ym(current_period$est_start),
    ym(current_period$est_end),
    min_n = 60L
  )

  table2_one_period <- portfolio_estimation_stats(
    memberships,
    estimation_betas,
    period_panel,
    market,
    ym(current_period$est_start),
    ym(current_period$est_end)
  ) %>%
    mutate(
      period = p,
      .before = 1
    )

  period_results[[as.character(p)]] <- list(
    period = p,
    period_info = current_period,
    panel = period_panel,
    memberships = memberships,
    table2 = table2_one_period
  )
}

table2 <- bind_rows(
  lapply(period_results, function(x) x$table2)
) %>%
  filter(period %in% TABLE2_PERIODS) %>%
  arrange(period, pf)

write_csv(
  table2,
  here(PATH_TAB, "table2_final.csv")
)

# -------------------------------------------------------------------------
# TABLE 3
# -------------------------------------------------------------------------

gamma_results <- list()

for (p in 1:9) {

  one_period <- period_results[[as.character(p)]]

  one_gamma <- run_testing_period(
    one_period$panel,
    market,
    one_period$memberships,
    est_start = one_period$period_info$est_start,
    test_start = one_period$period_info$test_start,
    test_end = one_period$period_info$test_end,
    cfg_min_obs = MIN_OBS_UPDATE
  ) %>%
    mutate(period = p)

  gamma_results[[as.character(p)]] <- one_gamma
}

gamma_monthly <- bind_rows(gamma_results)

write_csv(
  gamma_monthly,
  here(PATH_TAB, "gamma_monthly.csv")
)

rf <- read_rds(
  here(PATH_RAW, "ff_rf.rds")
) %>%
  transmute(
    ym = ym(date),
    rf = rf
  )

table3 <- summarise_table3(
  gamma_monthly,
  rf,
  TABLE3_PERIODS
)

write_csv(
  table3,
  here(PATH_TAB, "table3_final.csv")
)

message("Final Tables 1-3 written to output/tables/.")
