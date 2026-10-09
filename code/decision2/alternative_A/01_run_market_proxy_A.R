# 01_run_market_proxy_A.R
# Decision 2, Alternative A
# Developer: Jimmy Zhang
# Reviewer: Sheena Chen
#
# This alternative uses CRSP's published equal-weighted market return.
# It is intentionally simple and reproducible: no researcher-defined stock
# universe is reconstructed in this branch.

market_proxy_A <- function() {

  # Read the CRSP market-index file downloaded by the common data script.
  crsp_market <- readRDS(
    file.path(PATH_RAW, "crsp_msi.rds")
  )

  # Keep the equal-weighted total market return used as Rm.
  market_A <- crsp_market %>%
    transmute(
      ym = ym(date),
      rm = ewretd
    ) %>%
    filter(!is.na(rm)) %>%
    arrange(ym)

  return(market_A)
}
