# code/decision1/compare_decision1.R
# Compare both Decision 1 implementations after both have been completed.

source("code/common/00_setup.R")
source("code/decision1/alternative_A/eligibility_A.R")
source("code/decision1/alternative_B/01_run_eligibility_B.R")

panel <- readRDS(file.path(PATH_PROC, "panel.rds"))

alt_A <- eligibility_A(panel, PERIODS)
alt_B <- eligibility_B(panel, PERIODS, max_missing = 3L)

table_A <- alt_A %>%
  select(period, n_available, n_eligible) %>%
  rename(A_available = n_available, A_eligible = n_eligible)

table_B <- alt_B %>%
  select(period, n_available, n_eligible) %>%
  rename(B_available = n_available, B_eligible = n_eligible)

comparison <- table_A %>%
  left_join(table_B, by = "period") %>%
  mutate(
    B_minus_A = B_eligible - A_eligible
  )

write_csv(
  comparison,
  file.path(PATH_TAB, "decision1_comparison.csv")
)

# Membership overlap diagnostic.
overlap_results <- list()

for (p in 1:9) {

  A_members <- alt_A$eligible[[p]]
  B_members <- alt_B$eligible[[p]]

  overlap_results[[p]] <- data.frame(
    period = p,
    in_both = length(intersect(A_members, B_members)),
    only_A = length(setdiff(A_members, B_members)),
    only_B = length(setdiff(B_members, A_members))
  )
}

overlap_table <- bind_rows(overlap_results)

write_csv(
  overlap_table,
  file.path(PATH_TAB, "decision1_overlap.csv")
)

# Sensitivity promised in Part 2: compare tighter/looser tolerances.
sensitivity_results <- list()

for (this_tolerance in c(1L, 3L, 6L)) {

  one_result <- eligibility_B(
    panel,
    PERIODS,
    max_missing = this_tolerance
  ) %>%
    select(period, n_eligible) %>%
    mutate(max_missing = this_tolerance)

  sensitivity_results[[as.character(this_tolerance)]] <- one_result
}

sensitivity_table <- bind_rows(sensitivity_results)

write_csv(
  sensitivity_table,
  file.path(PATH_TAB, "decision1_B_sensitivity.csv")
)

print(comparison)
