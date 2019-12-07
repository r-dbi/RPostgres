library(DBI)

DBItest::make_context(
  Postgres(),
  NULL,
  name = "RPostgres",
  tweaks = DBItest::tweaks(
    placeholder_pattern = "$1",
    date_cast = function(x) paste0("date '", x, "'"),
    time_cast = function(x) paste0("time '", x, "'"),
    timestamp_cast = function(x) paste0("timestamp '", x, "'"),
    is_null_check = function(x) paste0("(", x, "::text IS NULL)"),
    blob_cast = function(x) paste0("(", x, "::bytea)")
  ),
  default_skip = c(
    # deliberately skipped, not required with upcoming version of DBI
    "get_info_driver",
    "get_info_result",

    NULL
  )
)
