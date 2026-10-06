# =============================================================================
# code/common/04_functions_fm.R
# Core Fama-MacBeth (1973) engine. Pure functions of (panel, market, config):
# no WRDS access and no decision-specific logic here, so Alternatives A/B for
# both decision points reuse exactly the same engine and differ only in the
# inputs they pass in. That is what makes the A-vs-B comparisons attributable
# to the decision itself rather than to incidental coding differences.
#
# Conventions:
#   panel  : tibble(permno, ym, date, ret, listed)   (02_build_panel.R)
#   market : tibble(ym, rm)                          (decision2 scripts)
#   Months are handled as ym = year*12 + month integers.
# =============================================================================

suppressPackageStartupMessages({ library(dplyr); library(tidyr); library(purrr) })

# ---------------------------------------------------------------------------
# estimate_betas(): market-model OLS per security over [ym_start, ym_end].
#   R_it = a_i + b_i * R_mt + e_it   (raw returns, as in FM eq. 8)
# Returns tibble(permno, n, beta, s_eps) where s_eps is the residual standard
# deviation with denominator (n - 2), i.e. the regression standard error.
# ---------------------------------------------------------------------------
estimate_betas <- function(panel, market, ym_start, ym_end, min_n = 2L) {
  dat <- panel |>
    filter(ym >= ym_start, ym <= ym_end, !is.na(ret)) |>
    inner_join(market, by = "ym")

  dat |>
    group_by(permno) |>
    summarise(
      n     = n(),
      beta  = ifelse(n >= min_n & stats::var(rm) > 0,
                     stats::cov(ret, rm) / stats::var(rm), NA_real_),
      alpha = mean(ret) - beta * mean(rm),
      s_eps = ifelse(n > 2,
                     sqrt(sum((ret - alpha - beta * rm)^2) / (n - 2)),
                     NA_real_),
      .groups = "drop"
    ) |>
    select(permno, n, beta, s_eps) |>
    filter(!is.na(beta))
}

# ---------------------------------------------------------------------------
# assign_portfolios(): FM's int(N/20) rule.
# Rank eligible securities by formation beta (ascending; portfolio 1 = lowest
# beta, portfolio 20 = highest). The middle 18 portfolios each hold
# int(N/20) securities; the first and last share the remainder, with the
# last (highest-beta) portfolio taking the extra security when N is odd
# (FM 1973, p. 615).
# Input : tibble(permno, beta). Output adds integer column pf in 1..n_pf.
# ---------------------------------------------------------------------------
assign_portfolios <- function(betas, n_pf = 20L) {
  N    <- nrow(betas)
  base <- N %/% n_pf
  rem  <- N - n_pf * base
  extra_first <- rem %/% 2L
  extra_last  <- rem - extra_first          # gets the odd one, per FM
  sizes <- c(base + extra_first, rep(base, n_pf - 2L), base + extra_last)
  stopifnot(sum(sizes) == N)

  betas |>
    arrange(beta, permno) |>                # permno breaks exact ties reproducibly
    mutate(pf = rep.int(seq_len(n_pf), times = sizes))
}

# ---------------------------------------------------------------------------
# portfolio_estimation_stats(): the statistics of FM's Table 2 for one
# period's estimation window, given fixed memberships and per-security
# estimates over that window.
#   members   : tibble(permno, pf)
#   sec_est   : tibble(permno, n, beta, s_eps) over the estimation window
#   panel/mkt : for the portfolio-level market-model regression
# Returns one row per portfolio:
#   beta_p   mean member beta                  (FM's beta_{p,t-1})
#   beta_ret beta of the portfolio-return series (identity check vs beta_p)
#   se_beta  s(ep) / (sqrt(n_m) * sd(rm))     (FM's s(beta_{p,t-1}))
#   r2       R^2 of portfolio market model     (r(Rp,Rm)^2)
#   s_rp     sd of monthly portfolio returns   (s(Rp))
#   s_ep     residual sd of portfolio model    (s(ep))
#   sbar_eps mean member residual sd           (s-bar_{p,t-1}(e_i))
#   ratio    s_ep / sbar_eps                   (diversification ratio)
# ---------------------------------------------------------------------------
portfolio_estimation_stats <- function(members, sec_est, panel, market,
                                       ym_start, ym_end) {
  ms <- members |> inner_join(sec_est, by = "permno")

  by_pf <- ms |>
    group_by(pf) |>
    summarise(n_sec    = n(),
              beta_p   = mean(beta),
              sbar_eps = mean(s_eps),
              .groups  = "drop")

  # Equal-weighted monthly portfolio returns over the estimation window
  pret <- panel |>
    inner_join(members, by = "permno") |>
    filter(ym >= ym_start, ym <= ym_end, !is.na(ret)) |>
    group_by(pf, ym) |>
    summarise(rp = mean(ret), .groups = "drop") |>
    inner_join(market, by = "ym")

  reg <- pret |>
    group_by(pf) |>
    summarise(
      n_m   = n(),
      b     = stats::cov(rp, rm) / stats::var(rm),
      a     = mean(rp) - b * mean(rm),
      s_rp  = stats::sd(rp),
      s_ep  = sqrt(sum((rp - a - b * rm)^2) / (n_m - 2)),
      r2    = stats::cor(rp, rm)^2,
      sd_rm = stats::sd(rm),
      .groups = "drop"
    ) |>
    mutate(se_beta = s_ep / (sqrt(n_m) * sd_rm))

  by_pf |>
    inner_join(reg, by = "pf") |>
    mutate(ratio = s_ep / sbar_eps, beta_ret = b) |>
    select(pf, n_sec, beta_p, beta_ret, se_beta, r2, s_rp, s_ep, sbar_eps, ratio)
}

# ---------------------------------------------------------------------------
# run_testing_period(): the month-by-month risk-return regressions for one
# period (FM eq. 10, estimated as Panels A-D).
#
# Security-level betas and residual sds are re-estimated each JANUARY on an
# expanding window from est_start through December of the previous year
# (FM p. 615-616: "updated yearly ... recomputed from monthly returns for
# 1930 through 1935, 1936, or 1937"). Within each month t, portfolio
# regressors are the simple averages over members with a valid return in t,
# "thus adjusting the portfolio beta month by month to allow for delisting
# of securities" (FM p. 615); the same member set defines the equal-weighted
# portfolio return. A member needs at least cfg_min_obs valid months in the
# expanding window to carry a current estimate (documented implementation
# decision); otherwise it drops out of that year's averages.
#
# Returns tibble(ym, date, panel_id, g0, g1, g2, g3, r2adj) with one row per
# month and regression panel ("A","B","C","D").
# ---------------------------------------------------------------------------
run_testing_period <- function(panel, market, members,
                               est_start, test_start, test_end,
                               cfg_min_obs = 24L) {
  ym_es <- ym(est_start); ym_ts <- ym(test_start); ym_te <- ym(test_end)
  test_months <- ym_ts:ym_te
  test_years  <- unique((test_months - 1L) %/% 12L)   # integer year index

  month_rows <- list()

  for (yr in test_years) {
    yr_months <- intersect(test_months, (yr * 12L + 1L):(yr * 12L + 12L))
    # Expanding estimation window: est_start .. Dec of previous year
    win_end <- yr * 12L                                  # December, year-1
    est <- estimate_betas(panel |> semi_join(members, by = "permno"),
                          market, ym_es, win_end, min_n = cfg_min_obs)
    est <- members |> inner_join(est, by = "permno") |>
      mutate(beta2 = beta^2)

    for (m in yr_months) {
      alive <- panel |>
        filter(ym == m, !is.na(ret)) |>
        inner_join(est, by = "permno")
      if (nrow(alive) == 0) next

      x <- alive |>
        group_by(pf) |>
        summarise(rp    = mean(ret),
                  bp    = mean(beta),
                  bp2   = mean(beta2),
                  sbar  = mean(s_eps),
                  .groups = "drop")
      if (nrow(x) < 5) next   # degenerate month; never expected with real data

      fits <- list(
        A = lm(rp ~ bp,               data = x),
        B = lm(rp ~ bp + bp2,         data = x),
        C = lm(rp ~ bp + sbar,        data = x),
        D = lm(rp ~ bp + bp2 + sbar,  data = x)
      )
      month_rows[[length(month_rows) + 1L]] <- imap_dfr(fits, function(f, id) {
        cf <- coef(f)
        tibble(ym = m, panel_id = id,
               g0 = cf[["(Intercept)"]],
               g1 = cf[["bp"]],
               g2 = ifelse("bp2"  %in% names(cf), cf[["bp2"]],  NA_real_),
               g3 = ifelse("sbar" %in% names(cf), cf[["sbar"]], NA_real_),
               r2adj = summary(f)$adj.r.squared)
      })
    }
  }

  bind_rows(month_rows) |>
    mutate(date = as.Date(sprintf("%d-%02d-01", (ym - 1L) %/% 12L, (ym - 1L) %% 12L + 1L)))
}

# ---------------------------------------------------------------------------
# summarise_table3(): FM's Table 3 statistics from the monthly coefficient
# series, for one reporting period and panel.
#   gbar_j            mean of monthly coefficients
#   s_j               sd of monthly coefficients
#   t_j               gbar_j / (s_j / sqrt(n))
#   gbar0_rf, t0_rf   mean and t of (g0_t - rf_t)
#   rho0_*            lag-1 serial correlation about an assumed zero mean
#                     (reported for g0 - rf, g2, g3, per FM)
#   rhoM_g1           lag-1 serial correlation about the sample mean (for g1)
#   r2bar, s_r2       mean and sd of monthly adjusted R^2
# ---------------------------------------------------------------------------
acf1_mean <- function(x) {
  x <- x[!is.na(x)]; n <- length(x); if (n < 3) return(NA_real_)
  xc <- x - mean(x); sum(xc[-1] * xc[-n]) / sum(xc^2)
}
acf1_zero <- function(x) {
  x <- x[!is.na(x)]; n <- length(x); if (n < 3) return(NA_real_)
  sum(x[-1] * x[-n]) / sum(x^2)
}

summarise_table3 <- function(gamma_monthly, rf, periods_df) {
  g <- gamma_monthly |> left_join(rf, by = "ym") |> mutate(g0rf = g0 - rf)

  purrr::pmap_dfr(periods_df, function(label, start, end) {
    sub <- g |> filter(ym >= ym(start), ym <= ym(end))
    sub |>
      group_by(panel_id) |>
      summarise(
        period  = label,
        n       = n(),
        gbar0   = mean(g0),            s0 = sd(g0),
        gbar1   = mean(g1),            s1 = sd(g1),
        gbar2   = mean(g2),            s2 = sd(g2),
        gbar3   = mean(g3),            s3 = sd(g3),
        gbar0rf = mean(g0rf),          s0rf = sd(g0rf),
        t0      = gbar0   / (s0   / sqrt(n)),
        t1      = gbar1   / (s1   / sqrt(n)),
        t2      = gbar2   / (s2   / sqrt(n)),
        t3      = gbar3   / (s3   / sqrt(n)),
        t0rf    = gbar0rf / (s0rf / sqrt(n)),
        rho0_g0rf = acf1_zero(g0rf),
        rhoM_g1   = acf1_mean(g1),
        rho0_g2   = acf1_zero(g2),
        rho0_g3   = acf1_zero(g3),
        r2bar   = mean(r2adj),
        s_r2    = sd(r2adj),
        .groups = "drop"
      )
  }) |>
    relocate(period, panel_id)
}
