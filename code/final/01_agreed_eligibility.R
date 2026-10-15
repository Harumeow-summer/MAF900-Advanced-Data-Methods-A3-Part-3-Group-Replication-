# code/final/01_agreed_eligibility.R
# Final Decision 1 implementation.
# Selected approach: Alternative A — Sheena's strict valid-return rule.
#
# This copy lives in final/ so the agreed replication does not depend on the
# alternative-development folders.

eligibility_final <- function(panel, periods) {

  results <- list()

  for (i in 1:nrow(periods)) {

    current_period <- periods[i, ]

    ym_form_start <- ym(current_period$form_start)
    ym_form_end <- ym(current_period$form_end)
    ym_est_start <- ym(current_period$est_start)
    ym_est_end <- ym(current_period$est_end)
    ym_test_start <- ym(current_period$test_start)

    required_est_months <- ym_est_end - ym_est_start + 1L

    available_stocks <- panel %>%
      filter(
        ym == ym_test_start,
        listed,
        !is.na(ret)
      ) %>%
      distinct(permno)

    stock_counts <- panel %>%
      semi_join(available_stocks, by = "permno") %>%
      group_by(permno) %>%
      summarise(
        est_valid_returns = sum(
          !is.na(ret) & ym >= ym_est_start & ym <= ym_est_end
        ),
        form_valid_returns = sum(
          !is.na(ret) & ym >= ym_form_start & ym <= ym_form_end
        ),
        .groups = "drop"
      )

    eligible_stocks <- stock_counts %>%
      filter(
        est_valid_returns == required_est_months,
        form_valid_returns >= 48L
      )

    results[[i]] <- tibble(
      period = current_period$period,
      n_available = nrow(available_stocks),
      n_eligible = nrow(eligible_stocks),
      eligible = list(eligible_stocks$permno)
    )
  }

  bind_rows(results)
}
