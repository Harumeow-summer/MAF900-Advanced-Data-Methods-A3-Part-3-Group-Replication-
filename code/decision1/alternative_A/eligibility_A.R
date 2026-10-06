# =============================================================================
# Decision 1, Alternative A — strict valid-return rule
# Developer: Sheena Chen
# Reviewer: Jimmy Zhang (review happens later)
# -----------------------------------------------------------------------------
# Part 2 definition:
#   available = NYSE common stock with a VALID RETURN in first testing month
#   eligible  = available AND
#               60/60 valid estimation-month returns AND
#               >= 48 valid formation-period returns
# =============================================================================

eligibility_A <- function(panel, periods) {

  purrr::pmap_dfr(
    periods,
    function(period, form_start, form_end,
             est_start, est_end, test_start, test_end) {

      ym_f1 <- ym(form_start)
      ym_f2 <- ym(form_end)
      ym_e1 <- ym(est_start)
      ym_e2 <- ym(est_end)
      ym_t1 <- ym(test_start)

      n_est <- ym_e2 - ym_e1 + 1L

      # Part 2 Alt A requires a valid return in the first testing month.
      avail <- panel |>
        dplyr::filter(
          ym == ym_t1,
          listed,
          !is.na(ret)
        ) |>
        dplyr::distinct(permno)

      counts <- panel |>
        dplyr::semi_join(avail, by = "permno") |>
        dplyr::group_by(permno) |>
        dplyr::summarise(
          n_est_valid = sum(!is.na(ret) & ym >= ym_e1 & ym <= ym_e2),
          n_form_valid = sum(!is.na(ret) & ym >= ym_f1 & ym <= ym_f2),
          .groups = "drop"
        )

      elig <- counts |>
        dplyr::filter(
          n_est_valid == n_est,
          n_form_valid >= 48L
        )

      tibble::tibble(
        period = period,
        n_available = nrow(avail),
        n_eligible = nrow(elig),
        eligible = list(elig$permno)
      )
    }
  )
}
