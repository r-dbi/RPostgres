do_package_checks()

if (ci_has_env("DEV_VERSIONS")) {
  get_stage("install") %>%
    add_step(step_install_github(c("r-dbi/DBI", "r-dbi/DBItest", "tidyverse/hms", "tidyverse/blob")))
}

if (ci_has_env("BUILD_PKGDOWN") && !ci_is_tag()) {
  get_stage("install") %>%
    add_step(step_install_github("r-lib/pkgload"))

  do_pkgdown()
}
