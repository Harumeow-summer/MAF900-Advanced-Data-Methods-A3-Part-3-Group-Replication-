# code/common/00_setup.R
# This script loads the packages used by the replication.
# It also loads the shared dates, decision settings, and folder paths.

library(tidyverse)
library(DBI)
library(here)
library(RPostgres)

source("config/config.R")

dir.create(here(PATH_RAW), recursive = TRUE, showWarnings = FALSE)
dir.create(here(PATH_PROC), recursive = TRUE, showWarnings = FALSE)
dir.create(here(PATH_TAB), recursive = TRUE, showWarnings = FALSE)
dir.create(here(PATH_LOG), recursive = TRUE, showWarnings = FALSE)
