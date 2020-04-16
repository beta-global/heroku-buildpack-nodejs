#!/usr/bin/env bash

YQ="$BP_DIR/lib/vendor/yq-$(get_os)"

detect_yarn2() {
  local uses_yarn="$1"
  local build_dir="$2"
  local yml_metadata
  local version

  yml_metadata=$($YQ r "$build_dir/yarn.lock" __metadata 2>&1)

  # grep for version in case the output is a parsing error
  version=$(echo "$yml_metadata" | grep version)

  if [[ "$uses_yarn" == "true" && "$version" != "" ]]; then
    echo "true"
  else
    echo "false"
  fi
}

fail_missing_yarnrc_yml() {
  local build_dir="$1"

  if [[ ! -f "$build_dir/.yarnrc.yml" ]]; then
    mcount "failures.missing-yarnrc-yml"
    metaset "failure" "missing-yarnrc-yml"
    header "Build failed"
    warn "The yarnrc.yml file could not found

      It looks like the yarnrc.yml file is missing from this project. Please
      make sure this file is checked into version control and made available to
      Heroku.

      To generate yarnrc.yml, make sure Yarn 2 is installed on your local
      machine and set the version in your project directory with:

       $ yarn set version berry
      "
    fail
  fi
}

fail_missing_yarn_path() {
  local build_dir="$1"
  local yarn_path="$2"

  if [[ "$yarn_path" == "" ]]; then
    mcount "failures.missing-yarn-path"
    metaset "failure" "missing-yarn-path"
    header "Build failed"
    warn "The 'yarnPath' could not be read from the yarnrc.yml file

      It looks like yarnrc.yml is missing the 'yarnPath' value, which is needed
      to identify the location of yarn for this build.

      To generate properly set 'yarnPath', make sure Yarn 2 is installed on your
      local machine and set the version in your project directory with:

       $ yarn set version berry
      "
    fail
  fi
}

fail_missing_yarn() {
  local build_dir="$1"
  local yarn_path="$2"

  if [[ -f "$build_dir/$yarn_path" ]]; then
    mcount "failures.missing-yarn-vendor"
    metaset "failure" "missing-yarn-vendor"
    header "Build failed"
    warn "Yarn was not found at $yarn_path

      It looks like yarn is missing from $yarn_path, which is needed to continue
      this build on Heroku. Yarn 2 recommends vendoring Yarn under the '.yarn'
      directory, so remember to check the '.yarn' directory into version control
      to use during builds.

      To generate the vendor correctly, make sure Yarn 2 is installed on your
      local machine and run the following in your project directory:

       $ yarn install
       $ yarn set version berry
      "
  fi
}

get_yarn_path() {
  local build_dir="$1"
  $YQ r "$build_dir/.yarnrc.yml" yarnPath 2>&1
}
