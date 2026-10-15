# code/final/02_agreed_market_proxy.R
# Final Decision 2 implementation.
# Selected approach: Alternative B — Sheena's reconstructed NYSE
# equal-weighted common-stock market proxy.

market_proxy_final <- function(panel) {

  market_final <- panel %>%
    filter(
      listed,
      !is.na(ret)
    ) %>%
    group_by(ym) %>%
    summarise(
      rm = mean(ret),
      n_stocks = n(),
      .groups = "drop"
    ) %>%
    arrange(ym)

  return(market_final)
}
