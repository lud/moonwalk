deps:
  mix deps.get

test:
  mix test

lint:
  mix compile --force --warnings-as-errors
  mix credo

dialyzer:
  mix dialyzer

_mix_format:
  mix format

_mix_check:
  mix check

_git_status:
  git status

docs:
  mix docs

changelog:
  git cliff -o CHANGELOG.md

check: deps _mix_format _mix_check docs _git_status

