do_package_checks()

if (ci_has_env("DEV_VERSIONS")) {
  get_stage("install") %>%
    add_step(step_install_github(c("r-dbi/DBI", "r-dbi/DBItest", "tidyverse/hms", "tidyverse/blob")))
}

# Build only for master or release branches
if (ci_has_env("BUILD_PKGDOWN") && grepl("^master$|^r-", ci_get_branch())) {
  do_pkgdown()
}
