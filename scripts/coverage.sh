#!/usr/bin/env bash

# Check is code passed tests and test coverage
echo "==> Checking that the code passing tests..."
set -euo pipefail

covermode=${COVERMODE:-atomic}
coverdir=$(mktemp -d /tmp/coverage.XXXXXXXXXX)
profile="${coverdir}/cover.out"

#pushd /
hash goveralls 2>/dev/null || go get github.com/mattn/goveralls
#popd

generate_cover_data() {
  for d in $(go list ./...) ; do
    (
      local output="${coverdir}/${d//\//-}.cover"
      go test -coverprofile="${output}" -covermode="$covermode" "$d"
    )
  done

  echo "mode: $covermode" >"$profile"
  grep -h -v "^mode:" "$coverdir"/*.cover >>"$profile"
}

push_to_coveralls() {
  goveralls -coverprofile="${profile}" -service=circle-ci
}

generate_cover_data
go tool cover -func "${profile}"

case "${1-}" in
  --html)
    go tool cover -html "${profile}"
    ;;
  --coveralls)
    push_to_coveralls
    ;;
esac
