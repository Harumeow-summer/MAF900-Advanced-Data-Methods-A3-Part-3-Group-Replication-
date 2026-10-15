# code/decision2/compare_decision2.R
# Compare the two Table 2 market-return proxies.
#
# Decision 1A is the agreed sample rule. The same eligible sample is used for
# both market proxies. Formation betas and portfolio assignments are then
# re-estimated separately under each Rm.

source("code/common/00_setup.R")
source("code/common/04_functions_fm.R")
source("code/decision1/alternative_A/eligibility_A.R")
source("code/decision2/alternative_A/01_run_market_proxy_A.R")
source("code/decision2/alternative_B/market_proxy_B.R")

panel <- read_rds(
  here(PATH_PROC, "panel.rds")
)

agreed_eligibility <- eligibility_A(panel, PERIODS)

market_A <- market_proxy_A()
market_B <- market_proxy_B(panel)

# -------------------------------------------------------------------------
# 1. Compare the two Rm series.
# -------------------------------------------------------------------------

series_comparison <- full_join(
  market_A %>% rename(rm_A = rm),
  market_B %>%
    select(ym, rm, n_stocks) %>%
    rename(rm_B = rm),
  by = "ym"
) %>%
  arrange(ym)

write_csv(
  series_comparison,
  here(PATH_TAB, "decision2_market_series.csv")
)

rm_summary <- series_comparison %>%
  filter(!is.na(rm_A), !is.na(rm_B)) %>%
  summarise(
    common_months = n(),
    correlation = cor(rm_A, rm_B),
    mean_absolute_difference = mean(abs(rm_A - rm_B)),
    minimum_B_constituents = min(n_stocks, na.rm = TRUE)
  )

write_csv(
  rm_summary,
  here(PATH_TAB, "decision2_market_summary.csv")
)

# -------------------------------------------------------------------------
# 2. Produce Table 2 under each market proxy.
# -------------------------------------------------------------------------

make_table2 <- function(market_data, proxy_label) {

  all_results <- list()

  for (p in TABLE2_PERIODS) {

    current_period <- PERIODS[PERIODS$period == p, ]
    eligible_permnos <- agreed_eligibility$eligible[[p]]

    period_panel <- panel %>%
      filter(permno %in% eligible_permnos)

    # Formation beta: at least 48 valid formation months.
    formation_betas <- estimate_betas(
      period_panel,
      market_data,
      ym(current_period$form_start),
      ym(current_period$form_end),
      min_n = 48L
    )

    portfolio_membership <- assign_portfolios(
      formation_betas %>% select(permno, beta),
      N_PORTFOLIOS
    ) %>%
      select(permno, pf)

    # Under selected DP1A, eligible stocks have 60 valid estimation returns.
    estimation_betas <- estimate_betas(
      period_panel,
      market_data,
      ym(current_period$est_start),
      ym(current_period$est_end),
      min_n = 60L
    )

    one_table <- portfolio_estimation_stats(
      portfolio_membership,
      estimation_betas,
      period_panel,
      market_data,
      ym(current_period$est_start),
      ym(current_period$est_end)
    ) %>%
      mutate(
        period = p,
        proxy = proxy_label,
        .before = 1
      )

    all_results[[as.character(p)]] <- one_table
  }

  bind_rows(all_results)
}

table2_A <- make_table2(market_A, "A")
table2_B <- make_table2(market_B, "B")

write_csv(
  table2_A,
  here(PATH_TAB, "table2_altA.csv")
)

write_csv(
  table2_B,
  here(PATH_TAB, "table2_altB.csv")
)

# -------------------------------------------------------------------------
# 3. Compare portfolio beta levels and ranks.
# -------------------------------------------------------------------------

beta_comparison <- table2_A %>%
  select(period, pf, beta_A = beta_p) %>%
  inner_join(
    table2_B %>% select(period, pf, beta_B = beta_p),
    by = c("period", "pf")
  ) %>%
  group_by(period) %>%
  summarise(
    beta_correlation = cor(beta_A, beta_B),
    beta_rank_correlation = cor(beta_A, beta_B, method = "spearman"),
    mean_absolute_beta_difference = mean(abs(beta_A - beta_B)),
    .groups = "drop"
  )

write_csv(
  beta_comparison,
  here(PATH_TAB, "decision2_beta_comparison.csv")
)

print(rm_summary)
print(beta_comparison)
