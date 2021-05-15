#!/bin/bash
set -e
set -o pipefail

if [ -z "${linting_path}" ] ; then
  echo " [!] Missing required input: linting_path"

  exit 1
fi

FLAGS=''

if [ -s "${lint_config_file}" ] ; then
  FLAGS=$FLAGS' --config '"${lint_config_file}"  
fi

cd "${linting_path}"

filename="swiftlint_report.txt"

report_path="~/${filename}"

run_swiftlint() {
    local filename="${1}"
    if [[ "${filename##*.}" == "swift" ]]; then
        swiftlint_output+=$"$(swiftlint lint --path "$swift_file" --reporter "xcode" "${FLAGS}")"
    fi
}

case $lint_range in 
  "changed")
    echo "Linting diff only"
    git fetch origin master
    git diff origin/master --name-only -- '*.swift' | while read filename; do run_swiftlint "${filename}"; done
    ;;
  "all")
    echo "Linting all files"
    swiftlint_output="$(swiftlint lint --reporter ${reporter} ${FLAGS})"
    ;;
esac

envman add --key "SWIFTLINT_REPORT" --value "${swiftlint_output}"
echo "Saved swiftlint output in SWIFTLINT_REPORT"

# This will print the `swiftlint_output` into a file and set the envvariable
# so it can be used in other tasks
echo "${swiftlint_output}" > $report_path
envman add --key "SWIFTLINT_REPORT_PATH" --value "${report_path}"
echo "Saved swiftlint output in file at path SWIFTLINT_REPORT_PATH"

if [ -s ${filename} ]
then
    echo 'Everything is fine!'
    exit 0
else
    echo 'You have some warning or errors!'
    exit 1
fi
