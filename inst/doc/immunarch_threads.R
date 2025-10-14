## ----eval=FALSE---------------------------------------------------------------
# # Limit the number of CPU threads used by DuckDB in this R session
# duckplyr::db_exec("SET threads TO 1")

## ----eval=FALSE---------------------------------------------------------------
# duckplyr::db_exec("SET threads TO 4")   # use 4 threads
# # or, if supported in your environment:
# duckplyr::db_exec("RESET threads")      # back to DuckDB default

