# 01_run_eligibility_B.R
# Decision 1, Alternative B
# Developer: Jimmy Zhang
# Reviewer: Sheena Chen
#
# This script uses a simple loop and step-by-step objects, following the
# beginner-friendly style used in the Assessment 2 repository.
#
# Rule from Part 2:
# 1. Listed as an NYSE common stock in the first testing month.
# 2. Continuously listed across all 60 estimation months.
# 3. At least 57 valid estimation returns (maximum 3 missing months).
# 4. At least 48 VALID formation-period returns.

eligibility_B <- function(panel, periods, max_missing = D1B_MAX_MISSING_EST) {

  results <- list()

  for (i in 1:nrow(periods)) {

    current_period <- periods[i, ]

    ym_form_start <- ym(current_period$form_start)
    ym_form_end <- ym(current_period$form_end)
    ym_est_start <- ym(current_period$est_start)
    ym_est_end <- ym(current_period$est_end)
    ym_test_start <- ym(current_period$test_start)

    required_est_months <- ym_est_end - ym_est_start + 1L

    # Step 1: securities available in the first testing month.
    available_stocks <- panel %>%
      filter(
        ym == ym_test_start,
        listed
      ) %>%
      distinct(permno)

    # Step 2: count listing and valid-return months for each available stock.
    stock_counts <- panel %>%
      semi_join(available_stocks, by = "permno") %>%
      group_by(permno) %>%
      summarise(
        est_listed_months = sum(
          listed & ym >= ym_est_start & ym <= ym_est_end
        ),
        est_valid_returns = sum(
          !is.na(ret) & ym >= ym_est_start & ym <= ym_est_end
        ),
        form_valid_returns = sum(
          !is.na(ret) & ym >= ym_form_start & ym <= ym_form_end
        ),
        .groups = "drop"
      )

    # Step 3: apply Jimmy's Alternative B rule.
    eligible_stocks <- stock_counts %>%
      filter(
        est_listed_months == required_est_months,
        est_valid_returns >= required_est_months - max_missing,
        form_valid_returns >= 48L
      )

    # Step 4: store the result for this FM period.
    results[[i]] <- tibble(
      period = current_period$period,
      n_available = nrow(available_stocks),
      n_eligible = nrow(eligible_stocks),
      eligible = list(eligible_stocks$permno)
    )
  }

  # Step 5: combine the nine periods.
  bind_rows(results)
}
