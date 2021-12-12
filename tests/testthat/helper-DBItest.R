library(DBI)

DBItest::make_context(
  Postgres(),
  NULL,
  name = "RPostgres",

  # Redshift:
  # Redshift(),
  # list(
  #   host = Sys.getenv("TMP_DB_REDSHIFT_HOST"),
  #   port = as.integer(Sys.getenv("TMP_DB_REDSHIFT_PORT")),
  #   user = Sys.getenv("TMP_DB_REDSHIFT_USER"),
  #   password = Sys.getenv("TMP_DB_REDSHIFT_PASSWORD")
  # ),
  # name = "Redshift",

  tweaks = DBItest::tweaks(
    # Redshift:
    # omit_blob_tests = TRUE,

    dbitest_version = "1.7.2",

    # immediate = TRUE:
    placeholder_pattern = "$1",
    # Redshift:
    # placeholder_pattern = character(),
    date_cast = function(x) paste0("date '", x, "'"),
    time_cast = function(x) paste0("time '", x, "'"),
    timestamp_cast = function(x) paste0("timestamp '", x, "'"),
    is_null_check = function(x) paste0("(", x, "::text IS NULL)"),
    blob_cast = function(x) paste0("(", x, "::bytea)")
  ),
  default_skip = c(
    # Not implemented correctly for i386
    if (.Platform$r_arch == "i386") "append_roundtrip_timestamp",
    if (.Platform$r_arch == "i386") "roundtrip_timestamp",

    if (getRversion() < "3.6") "compliance",

    NULL
  )
)
