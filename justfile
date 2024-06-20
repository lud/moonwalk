gen-test-suite:
  MIX_ENV=test mix gen.test.suite draft2020-12
  MIX_ENV=test mix gen.test.suite draft2019-09
  # mix gen.test.suite latest