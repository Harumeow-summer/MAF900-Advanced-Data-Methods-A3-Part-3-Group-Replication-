# code/common/00_setup.R
# Shared setup used by all scripts.

library(tidyverse)
library(DBI)
library(RPostgres)
library(here)

source("config/config.R")

dir.create(PATH_RAW, recursive = TRUE, showWarnings = FALSE)
dir.create(PATH_PROC, recursive = TRUE, showWarnings = FALSE)
dir.create(PATH_TAB, recursive = TRUE, showWarnings = FALSE)
