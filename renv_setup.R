# Run once near the end of the project, after packages are stable.
if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv")
}
renv::init(bare = TRUE)
renv::snapshot()
