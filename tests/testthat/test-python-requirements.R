test_that("torch requirements are pinned only on Windows", {
  expect_equal(
    actinet:::actinet_python_packages("windows"),
    c("actinet==0.7.2", "torch==2.8.0", "torchvision==0.23.0")
  )
  expect_equal(
    actinet:::actinet_python_packages("unix"),
    "actinet==0.7.2"
  )
})
