test_that("renamer replaces selected column names", {
  data = data.frame(a = 1, b = 2, c = 3)

  expect_named(
    actinet:::renamer(data, old = c("a", "c"), new = c("x", "z")),
    c("x", "b", "z")
  )
  expect_error(
    actinet:::renamer(data, old = c("a", "b"), new = "x")
  )
})

test_that("sc_rename_data normalizes required accelerometer columns", {
  time = as.POSIXct("2024-01-01 00:00:00", tz = "UTC")

  data = data.frame(time = time, x = 1, y = 2, z = 3, extra = 4)
  expect_named(
    actinet:::sc_rename_data(data),
    c("time", "x", "y", "z", "extra")
  )

  header_timestamp = data.frame(
    HEADER_TIME_STAMP = time,
    X = 1,
    Y = 2,
    Z = 3
  )
  expect_named(
    actinet:::sc_rename_data(header_timestamp),
    c("time", "x", "y", "z")
  )

  already_named = data.frame(
    HEADER_TIMESTAMP = time,
    X = 1,
    Y = 2,
    Z = 3
  )
  expect_named(
    actinet:::sc_rename_data(already_named),
    c("time", "x", "y", "z")
  )

  expect_error(actinet:::sc_rename_data(list(x = 1)))
  expect_error(actinet:::sc_rename_data(data.frame(x = 1, y = 2, z = 3)))
})

test_that("sc_write_csv writes normalized timestamps", {
  data = data.frame(
    TIME = as.POSIXct("2024-01-01 00:00:00.123", tz = "UTC"),
    X = 1,
    Y = 2,
    Z = 3
  )
  path = actinet:::sc_write_csv(data)

  expect_true(file.exists(path))
  expect_match(readLines(path)[2], "2024-01-01 00:00:00\\.\\d{3},1,2,3")
})

test_that("null-or validators accept NULL and validate values", {
  expect_true(actinet:::null_or_scalar(NULL))
  expect_true(actinet:::null_or_scalar(1))
  expect_false(actinet:::null_or_scalar(1:2))

  expect_true(actinet:::null_or_string(NULL))
  expect_true(actinet:::null_or_string("x"))
  expect_false(actinet:::null_or_string(c("x", "y")))

  expect_true(actinet:::null_or_count(NULL))
  expect_true(actinet:::null_or_count(1))
  expect_false(actinet:::null_or_count(1.5))

  expect_true(actinet:::null_or_logical(NULL))
  expect_true(actinet:::null_or_logical(TRUE))
  expect_false(actinet:::null_or_logical(c(TRUE, FALSE)))

  expect_true(actinet:::null_or_true(NULL))
  expect_true(actinet:::null_or_true(TRUE))
  expect_false(actinet:::null_or_true(FALSE))
})

test_that("transform_data_to_files handles data frames, lists, and paths", {
  data = data.frame(
    time = as.POSIXct("2024-01-01 00:00:00", tz = "UTC"),
    x = 1,
    y = 2,
    z = 3
  )
  file = tempfile(fileext = ".csv")
  writeLines("a", file)

  expect_message(
    from_data <- actinet:::transform_data_to_files(data, verbose = TRUE),
    "Checking Data"
  )
  expect_true(file.exists(from_data))
  expect_true(isTRUE(attr(from_data, "remove_file")))

  from_path = actinet:::transform_data_to_files(file, verbose = FALSE)
  expect_identical(unname(from_path), file)
  expect_named(from_path, file)

  from_list = actinet:::transform_data_to_files(list(data, file), verbose = FALSE)
  expect_length(from_list, 2)
  expect_true(all(file.exists(from_list)))
  expect_equal(names(from_list), unname(from_list))

  expect_message(
    actinet:::transform_data_to_files(list(data), verbose = TRUE),
    "Writing file to CSV"
  )
})

test_that("module helpers query reticulate state", {
  testthat::local_mocked_bindings(
    py_module_available = function(module) identical(module, "numpy"),
    py_list_packages = function() {
      data.frame(package = "numpy", version = "1.2.3")
    },
    .package = "reticulate"
  )

  expect_true(actinet:::module_version("numpy") == "1.2.3")
  expect_error(actinet:::module_version("missing"), "missing is not installed")
  expect_true(have_actinet() == FALSE)
})

test_that("actinet_check validates module availability and version", {
  testthat::local_mocked_bindings(
    have_actinet = function() TRUE,
    actinet_version = function() "0.7.2",
    .package = "actinet"
  )
  expect_true(actinet_check())

  testthat::local_mocked_bindings(
    have_actinet = function() FALSE,
    actinet_version = function() "0.7.2",
    .package = "actinet"
  )
  expect_false(actinet_check())

  testthat::local_mocked_bindings(
    have_actinet = function() TRUE,
    actinet_version = function() "0.7.1",
    .package = "actinet"
  )
  expect_false(actinet_check())

  testthat::local_mocked_bindings(
    have_actinet = function() TRUE,
    actinet_version = function() stop("unavailable"),
    .package = "actinet"
  )
  expect_false(actinet_check())
})

test_that("actinet_version delegates to module_version", {
  testthat::local_mocked_bindings(
    module_version = function(module) paste0(module, "-version"),
    .package = "actinet"
  )
  expect_equal(actinet_version(), "actinet-version")
})

test_that("classifier helpers return expected model metadata", {
  expect_equal(
    actinet:::ac_classifier("walmsley"),
    "ssl-ukb-c24-rw-30s-20260128"
  )
  expect_equal(
    actinet:::ac_classifier("willetts"),
    "ssl-ukb-c24-mw-30s-20260128"
  )
  expect_equal(
    actinet:::ac_model_md5("walmsley"),
    "a829041ba84b18084b4b2897fb1b36a6"
  )
  expect_equal(
    actinet:::ac_model_md5("willetts"),
    "59a9492b50ee922c7a31f88888c5f14b"
  )
  expect_equal(
    ac_model_filename("walmsley"),
    "ssl-ukb-c24-rw-30s-20260128.joblib.lzma"
  )
})

test_that("check_versions validates Python classifier metadata", {
  testthat::local_mocked_bindings(
    import = function(module, convert = TRUE) {
      expect_equal(module, "actinet.__init__")
      expect_true(convert)
      list(
        `__classifiers__` = list(
          walmsley = list(
            version = "ssl-ukb-c24-rw-30s-20260128",
            md5 = "a829041ba84b18084b4b2897fb1b36a6"
          ),
          willetts = list(
            version = "ssl-ukb-c24-mw-30s-20260128",
            md5 = "59a9492b50ee922c7a31f88888c5f14b"
          )
        )
      )
    },
    .package = "reticulate"
  )

  expect_no_error(actinet:::check_versions())
})

test_that("ac_load_model imports and loads classifier paths", {
  captured = NULL
  convert_values = NULL

  testthat::local_mocked_bindings(
    import = function(module, convert = TRUE) {
      expect_equal(module, "actinet.actinet")
      convert_values <<- c(convert_values, convert)
      list(load_classifier = function(model_repo_path, classifier, force_download) {
        captured <<- list(
          model_repo_path = model_repo_path,
          classifier = classifier,
          force_download = force_download
        )
        "model"
      })
    },
    .package = "reticulate"
  )

  model_path = tempfile()
  expect_equal(
    ac_load_model("willetts", model_path = model_path, force_download = TRUE),
    "model"
  )
  expect_equal(captured$model_repo_path, path.expand(model_path))
  expect_equal(captured$classifier, "willetts")
  expect_true(captured$force_download)

  expect_equal(ac_load_model("walmsley", as_python = FALSE), "model")
  expect_equal(convert_values, c(FALSE, TRUE))
  expect_match(captured$model_repo_path, "walmsley\\.joblib\\.lzma$")
})

test_that("ac_download_model downloads and verifies checksums", {
  captured = NULL
  model_path = tempfile()

  testthat::local_mocked_bindings(
    curl_download = function(url, destfile) {
      captured <<- list(url = url, destfile = destfile)
      writeLines("model", destfile)
      destfile
    },
    .package = "curl"
  )
  testthat::local_mocked_bindings(
    md5sum = function(files) {
      stats::setNames("a829041ba84b18084b4b2897fb1b36a6", files)
    },
    .package = "tools"
  )

  expect_equal(ac_download_model(model_path, classifier = "walmsley"), model_path)
  expect_match(captured$url, "ssl-ukb-c24-rw-30s-20260128\\.joblib\\.lzma$")
  expect_equal(captured$destfile, model_path)

  testthat::local_mocked_bindings(
    md5sum = function(files) stats::setNames("not-the-md5", files),
    .package = "tools"
  )
  expect_error(ac_download_model(model_path, classifier = "walmsley"))
})

test_that("actinet builds CLI arguments and returns output paths", {
  captured = NULL
  input = tempfile(fileext = ".csv")
  model_path = tempfile()
  outdir = tempfile()
  writeLines("time,x,y,z", input)
  writeLines("model", model_path)

  testthat::local_mocked_bindings(
    import = function(module) {
      expect_equal(module, "actinet.actinet")
      list(resolve_path = function(file) list(dirname(file), "sample"))
    },
    uv_run_tool = function(tool, args, python_version) {
      captured <<- list(tool = tool, args = args, python_version = python_version)
      invisible(NULL)
    },
    .package = "reticulate"
  )

  result = actinet(
    file = input,
    outdir = outdir,
    classifier = "walmsley",
    sample_rate = 100,
    model_path = model_path,
    pytorch_device = "cpu",
    no_hmm = TRUE,
    require_sleep_above = "2H",
    single_sleep_block = TRUE,
    force_download = TRUE,
    exclude_first_last = "both",
    exclude_wear_below = "12H",
    csv_start_row = 2,
    csv_txyz = c("time", "x", "y", "z"),
    csv_txyz_idxs = 0:3,
    csv_date_format = "%Y-%m-%d",
    calibration_stdtol_min = 0.01,
    plot_activity = TRUE,
    cache_classifier = TRUE,
    verbose = FALSE
  )

  expect_equal(captured$tool, "actinet")
  expect_equal(captured$python_version, "3.10")
  expect_true(normalizePath(input, winslash = "/") %in% captured$args)
  expect_true(all(c(
    "--sample-rate=100",
    "--no-hmm",
    "--single-sleep-block",
    "--force-download",
    "--plot-activity",
    "--quiet",
    "--cache-classifier",
    "--exclude-first-last=both",
    "--classifier=walmsley",
    "--csv-start-row=2",
    "--calibration-stdtol-min=0.01"
  ) %in% captured$args))
  expect_true(any(grepl("^--outdir=", captured$args)))
  expect_true(any(grepl("^--require-sleep-above=", captured$args)))
  expect_true(any(grepl("^--exclude-wear-below=", captured$args)))
  expect_true(any(grepl("^--pytorch-device=", captured$args)))
  expect_true(any(grepl("^--csv-date-format=", captured$args)))
  expect_true(any(grepl("^--csv-txyz=", captured$args)))
  expect_true(any(grepl("^--csv-txyz-idxs=", captured$args)))
  expect_true(any(grepl("^--model-repo-path=", captured$args)))

  expected_outdir = normalizePath(outdir, winslash = "/", mustWork = FALSE)
  expect_equal(result$outdir_passed, expected_outdir)
  expect_equal(result$outdir, file.path(expected_outdir, "sample", fsep = "/"))
  expect_equal(
    basename(result$outfiles),
    c("sample-timeSeries.csv.gz", "sample-outputSummary.json", "sample-Daily.csv.gz")
  )
})

test_that("actinet removes temporary CSV files created from data frames", {
  captured_file = NULL
  data = data.frame(
    time = as.POSIXct("2024-01-01 00:00:00", tz = "UTC"),
    x = 1,
    y = 2,
    z = 3
  )

  testthat::local_mocked_bindings(
    import = function(module) {
      list(resolve_path = function(file) list(dirname(file), "sample"))
    },
    uv_run_tool = function(tool, args, python_version) {
      captured_file <<- tail(args, 1)
      expect_true(file.exists(captured_file))
      invisible(NULL)
    },
    .package = "reticulate"
  )

  expect_message(result <- actinet(data, verbose = TRUE), "Writing file to CSV")
  expect_equal(basename(result$outdir), "sample")
  expect_false(file.exists(captured_file))
})

test_that("actinet validates arguments before invoking Python", {
  expect_error(actinet("missing.csv", sample_rate = 1.5))
  expect_error(actinet("missing.csv", no_hmm = c(TRUE, FALSE)))
  expect_error(actinet("missing.csv", exclude_first_last = "middle"))
  expect_error(actinet("missing.csv", model_path = "missing-model"))
})

test_that(".onLoad declares the Python dependency", {
  captured = NULL

  testthat::local_mocked_bindings(
    py_require = function(packages, python_version) {
      captured <<- list(packages = packages, python_version = python_version)
      invisible(NULL)
    },
    .package = "reticulate"
  )

  actinet:::.onLoad(tempdir(), "actinet")

  expect_equal(captured$packages, "actinet==0.7.2")
  expect_equal(captured$python_version, "3.10")
})
