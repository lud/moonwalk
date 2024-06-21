gen-test-suite:
  MIX_ENV=test mix gen.test.suite draft2020-12
  MIX_ENV=test mix gen.test.suite draft7
  # mix gen.test.suite latest