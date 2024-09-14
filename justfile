gen-test-suite:
  mix gen.test.suite draft2020-12
  mix gen.test.suite draft7
  # mix gen.test.suite latest
  mix format
  git status --porcelain > /dev/null | rg "test/generated" && mix test || true


test:
  mix test

lint:
  mix credo
  # mix compile --force --warnings-as-errors

_mix_format:
  mix format

_git_status:
  git status

check: _mix_format test lint _git_status

