# code/decision2/alternative_A/01_run_market_proxy_A.R
# Decision 2, Alternative A
# Developer: Jimmy Zhang
# Reviewer: Sheena Chen
#
# This alternative uses CRSP's published equal-weighted market return.
# It is easy to reproduce, but its maintained market universe is not a
# constant NYSE-only universe over the full Fama-MacBeth sample.

market_proxy_A <- function() {

  crsp_market <- read_rds(
    here(PATH_RAW, "crsp_msi.rds")
  )

  market_A <- crsp_market %>%
    transmute(
      ym = ym(date),
      rm = ewretd
    ) %>%
    filter(!is.na(rm)) %>%
    arrange(ym)

  return(market_A)
}
