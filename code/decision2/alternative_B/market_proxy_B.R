# =============================================================================
# Decision 2, Alternative B — reconstructed EW NYSE common-stock index
# Developer: Sheena Chen
# Reviewer: Jimmy Zhang (review happens later)
# -----------------------------------------------------------------------------
# Reconstruct Rm each month as the simple average of VALID returns for all
# date-valid NYSE common stocks. Do not restrict the index to DP1-eligible
# securities.
#
# No arbitrary n >= 50 deletion rule is imposed. Instead, n_stocks is retained
# as a diagnostic so sparse months are visible.
# =============================================================================

market_proxy_B <- function(panel) {

  panel |>
    dplyr::filter(
      listed,
      !is.na(ret)
    ) |>
    dplyr::group_by(ym) |>
    dplyr::summarise(
      rm = mean(ret),
      n_stocks = dplyr::n(),
      .groups = "drop"
    ) |>
    dplyr::arrange(ym)
}
