actinet_check_result = function() {
  tryCatch(
    suppressMessages(suppressWarnings(actinet_check())),
    error = function(e) FALSE
  )
}

skip_if_actinet_unavailable = function() {
  skip_on_cran()
  skip_if_not(
    actinet_check_result(),
    "The required Python actinet module is unavailable"
  )
  skip_if_not(curl::has_internet(), "Internet access is unavailable")
}

skip_on_model_download_error = function(code) {
  tryCatch(
    code(),
    error = function(e) {
      message = conditionMessage(e)
      is_network_error = grepl(
        "download|network|internet|connection|resolve|timeout|timed out|ssl|certificate|http|url|fetch",
        message,
        ignore.case = TRUE
      )
      if (is_network_error) {
        skip(paste("The external actinet model could not be downloaded:",
                   message))
      }
      stop(e)
    }
  )
}

test_that("actinet runs the Python CLI and writes output files", {
  skip_if_actinet_unavailable()

  input = system.file("extdata/P30_wrist100.csv.gz", package = "actinet")
  expect_true(nzchar(input))

  outdir = tempfile("actinet-output-")
  dir.create(outdir)
  on.exit(unlink(outdir, recursive = TRUE), add = TRUE)
  result = skip_on_model_download_error(function() {
    actinet(
      file = input,
      outdir = outdir,
      classifier = "walmsley",
      no_hmm = TRUE,
      verbose = FALSE
    )
  })

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


test_that("py_actinet runs the Python CLI and writes output files", {
  skip_if_actinet_unavailable()

  input = system.file("extdata/P30_wrist100.csv.gz", package = "actinet")
  expect_true(nzchar(input))

  outdir = tempfile("actinet-output-")
  dir.create(outdir)
  on.exit(unlink(outdir, recursive = TRUE), add = TRUE)
  result = skip_on_model_download_error(function() {
    py_actinet(
      file = input,
      outdir = outdir,
      classifier = "walmsley",
      no_hmm = TRUE,
      verbose = FALSE
    )
  })

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
