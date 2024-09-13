gen-test-suite:
  MIX_ENV=test mix gen.test.suite draft2020-12
  MIX_ENV=test mix gen.test.suite draft7
  # mix gen.test.suite latest
  mix format

test:
  mix test

lint:
  mix credo
  # mix compile --force --warnings-as-errors

_git_status:
  git status

check: test lint _git_status

