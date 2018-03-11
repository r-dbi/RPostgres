add_package_checks()

get_stage("deploy") %>%
  add_step(step_build_pkgdown())

if (Sys.getenv("id_rsa") != "" && Sys.getenv("BUILD_PKGDOWN") != "") {
  get_stage("before_deploy") %>%
    add_step(step_install_ssh_keys()) %>%
    add_step(step_test_ssh())

  get_stage("deploy") %>%
    add_step(step_push_deploy())
}
