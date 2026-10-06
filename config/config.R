# config/config.R
# Shared parameters for the Fama-MacBeth (1973) replication.

SAMPLE_START <- as.Date("1926-01-01")
SAMPLE_END   <- as.Date("1968-06-30")

# Part 2 Decision 1, Alternative B:
# allow at most 3 missing estimation-month returns (= 5% of 60 months).
D1B_MAX_MISSING_EST <- 3L

# IMPORTANT:
# This is a documented implementation parameter, not one of the two formal
# decision points. Keep it visible and justify/check it before final submission.
MIN_OBS_UPDATE <- 24L

# Do NOT set these to A/B until the reciprocal reviews and joint decision records
# have been completed.
FINAL_DECISION1 <- NA_character_
FINAL_DECISION2 <- NA_character_

PERIODS <- data.frame(
  period     = 1:9,
  form_start = as.Date(c("1926-01-01","1927-01-01","1931-01-01","1935-01-01",
                         "1939-01-01","1943-01-01","1947-01-01","1951-01-01",
                         "1955-01-01")),
  form_end   = as.Date(c("1929-12-31","1933-12-31","1937-12-31","1941-12-31",
                         "1945-12-31","1949-12-31","1953-12-31","1957-12-31",
                         "1961-12-31")),
  est_start  = as.Date(c("1930-01-01","1934-01-01","1938-01-01","1942-01-01",
                         "1946-01-01","1950-01-01","1954-01-01","1958-01-01",
                         "1962-01-01")),
  est_end    = as.Date(c("1934-12-31","1938-12-31","1942-12-31","1946-12-31",
                         "1950-12-31","1954-12-31","1958-12-31","1962-12-31",
                         "1966-12-31")),
  test_start = as.Date(c("1935-01-01","1939-01-01","1943-01-01","1947-01-01",
                         "1951-01-01","1955-01-01","1959-01-01","1963-01-01",
                         "1967-01-01")),
  test_end   = as.Date(c("1938-12-31","1942-12-31","1946-12-31","1950-12-31",
                         "1954-12-31","1958-12-31","1962-12-31","1966-12-31",
                         "1968-06-30"))
)

TABLE2_PERIODS <- c(2L, 4L, 6L, 8L)

TABLE3_PERIODS <- data.frame(
  label = c("1935-6/68","1935-45","1946-55","1956-6/68",
            "1935-40","1941-45","1946-50","1951-55","1956-60","1961-6/68"),
  start = as.Date(c("1935-01-01","1935-01-01","1946-01-01","1956-01-01",
                    "1935-01-01","1941-01-01","1946-01-01","1951-01-01",
                    "1956-01-01","1961-01-01")),
  end   = as.Date(c("1968-06-30","1945-12-31","1955-12-31","1968-06-30",
                    "1940-12-31","1945-12-31","1950-12-31","1955-12-31",
                    "1960-12-31","1968-06-30"))
)

N_PORTFOLIOS <- 20L

PATH_RAW  <- "data/raw"
PATH_PROC <- "data/processed"
PATH_TAB  <- "output/tables"

ym <- function(d) {
  as.integer(format(d, "%Y")) * 12L + as.integer(format(d, "%m"))
}
