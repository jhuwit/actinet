actinet_check_result = function() {
  res = try({suppressWarnings(actinet_check())})
  if (inherits(res, "try-error")) {
    res = FALSE
  }
  res
}

test_that("actinet runs the Python CLI and writes output files", {
  skip_on_cran()
  skip_if_not(actinet_check_result(),
              "The required Python actinet module is unavailable")

  input = system.file("extdata/P30_wrist100.csv.gz", package = "actinet")
  expect_true(nzchar(input))

  outdir = tempfile("actinet-output-")
  dir.create(outdir)
  on.exit(unlink(outdir, recursive = TRUE), add = TRUE)
  result = actinet(
    file = input,
    outdir = outdir,
    classifier = "walmsley",
    no_hmm = TRUE,
    verbose = FALSE
  )

  expect_true(dir.exists(result$outdir))
  expect_true(all(file.exists(result$outfiles)))
  expect_true(all(file.info(result$outfiles)$size > 0))

  time_series = readr::read_csv(
    result$outfiles[[1]],
    show_col_types = FALSE,
    progress = FALSE
  )
  expect_gt(nrow(time_series), 0)
  expect_false(inherits(result$data$summary, "try-error"))

  daily = readr::read_csv(
    result$outfiles[[3]],
    show_col_types = FALSE,
    progress = FALSE
  )
  expect_gt(nrow(daily), 0)
})


test_that("actinet runs the Python CLI and writes output files", {
  skip_on_cran()
  skip_if_not(actinet_check_result(),
              "The required Python actinet module is unavailable")

  input = system.file("extdata/P30_wrist100.csv.gz", package = "actinet")
  expect_true(nzchar(input))

  outdir = tempfile("actinet-output-")
  dir.create(outdir)
  on.exit(unlink(outdir, recursive = TRUE), add = TRUE)
  result = py_actinet(
    file = input,
    outdir = outdir,
    classifier = "walmsley",
    no_hmm = TRUE,
    verbose = FALSE
  )

  expect_true(dir.exists(result$outdir))
  expect_true(all(file.exists(result$outfiles)))
  expect_true(all(file.info(result$outfiles)$size > 0))

  time_series = readr::read_csv(
    result$outfiles[[1]],
    show_col_types = FALSE,
    progress = FALSE
  )
  expect_gt(nrow(time_series), 0)
  expect_false(inherits(result$data$summary, "try-error"))

  daily = readr::read_csv(
    result$outfiles[[3]],
    show_col_types = FALSE,
    progress = FALSE
  )
  expect_gt(nrow(daily), 0)
})
