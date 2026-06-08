renamer = function(data, old, new) {
  stopifnot(length(old) == length(new))
  cn = colnames(data)
  cn[cn %in% old] = new
  colnames(data) = cn
  data
}

sc_rename_data = function(data) {
  HEADER_TIMESTAMP = TIME = HEADER_TIME_STAMP = X = Y = Z = NULL
  rm(list = c("HEADER_TIMESTAMP", "HEADER_TIME_STAMP", "X", "Y", "Z",
              "TIME"))
  assertthat::assert_that(
    is.data.frame(data)
  )
  # uppercase
  colnames(data) = toupper(colnames(data))
  cn = colnames(data)
  if ("TIME" %in% cn && !"HEADER_TIMESTAMP" %in% cn) {
    data = renamer(data, old = "TIME", new = "HEADER_TIMESTAMP")
  }
  if ("HEADER_TIME_STAMP" %in% cn && !"HEADER_TIMESTAMP" %in% cn) {
    data = renamer(data, old = "HEADER_TIME_STAMP", new = "HEADER_TIMESTAMP")
  }
  stopifnot(all(c("X", "Y", "Z", "HEADER_TIMESTAMP") %in% colnames(data)))
  data = renamer(data, old = "HEADER_TIMESTAMP", new = "time")
  colnames(data) = tolower(colnames(data))
  data
}

sc_write_csv = function(data, path = tempfile(fileext = ".csv")) {
  data = sc_rename_data(data = data)
  opts = options()
  on.exit(options(opts), add = TRUE)
  options(digits.secs = 3)
  data$time = format(data$time, "%Y-%m-%d %H:%M:%OS3")
  readr::write_csv(x = data, file = path, progress = FALSE)
  return(path)
}



null_or_scalar = function(x) {
  is.null(x) || assertthat::is.scalar(x)
}

null_or_string = function(x) {
  is.null(x) || assertthat::is.string(x)
}

null_or_count = function(x) {
  is.null(x) || assertthat::is.count(x)
}

null_or_logical = function(x) {
  is.null(x) || assertthat::is.flag(x)
}

null_or_true = function(x) {
  is.null(x) || as.logical(x)
}


#' Run Actinet Model on Data
#'
#' @param file accelerometry file to process, including CSV,
#' CWA, GT3X, and `GENEActiv` bin files
#' @param verbose print diagnostic messages
#' @param sample_rate the sample rate of the data.  Set to `NULL`
#' for `actinet` to try to guess this
#' @param outdir folder location to save output files
#' @param classifier Enter custom activity classifier file to use. Default: walmsley (Walmsley2020 annotations of activity intensity). Can also enter path to local classifier (.joblib.lzma) file.
#' @param no_hmm Disable HMM post-processing
#' @param require_sleep_above Require sleep blocks to exceed a minimum duration, otherwise be classified as sedentary. Pass values as strings, e.g.: '2H', '30min'. Default: None (no requirement)
#' @param single_sleep_block Recognize only one sleep block per day, all other sleep blocks will be converted to sedentary
#' @param force_download  Force download of classifier file
#' @param pytorch_device torch device to use, e.g.: 'cpu' or 'cuda:0'. Default: 'mps' if available, otherwise 'cpu'
#' @param sample_rate Sample rate for measurement, otherwise inferred.
#' @param exclude_first_last {first,last,both} Exclude first, last or both days of data. Default: None (no exclusion)
#' @param exclude_wear_below Exclude days with wear time below threshold. Pass values as strings, e.g.: '12H', '30min'. Default: None (no exclusion)
#' @param csv_start_row Row number to start reading a CSV file. Default: 1 (First row)
#' @param csv_txyz CSV_TXYZ Column names for time, x, y, z in CSV files. Comma_ separated string. Default: 'time,x,y,z'
#' @param csv_txyz_idxs Column indices for time,x,y,z (0_indexed, e.g., '0,1,2,3'). Overrides csv_txyz.
#' @param csv_date_format Date time format for csv file when reading a csv file. See https://docs.python.org/3/library/datetime.html#strftime_and_strptime_format_codes for more possible codes. Default: '%Y-%m-%d %H:%M:%S.%f' (e.g. '2023-10-01 12:34:56.789')
#' @param calibration_stdtol_min Minimum standard deviation tolerance (g) for detecting stationary periods for calibration. Default: None
#' @param plot_activity Plot the predicted activity labels
#' @param cache_classifier  Download and cache classifier file and model modules for offline usage
#'
#' @param model_path the file path to the model.  If on disk, this can be
#' re-used and not re-downloaded.  If `NULL`, will download to the
#' temporary directory
#'
#' @return A list of the results (`data.frame`),
#' summary of the results, adjusted summary of the results, and
#' information about the data.
#' @export
#'
#' @examples
#' \donttest{
#'   library(magrittr)
#'   file = system.file("extdata/P30_wrist100.csv.gz", package = "actinet")
#'   if (actinet_check()) {
#'     out = actinet(file = file)
#'     st = out$step_times
#'   }
#' }
#'
actinet = function(
    file,
    outdir = tempfile(),
    classifier = NULL,
    sample_rate = NULL,
    model_path = NULL,
    pytorch_device = NULL,
    no_hmm = FALSE,
    require_sleep_above = NULL,
    single_sleep_block = FALSE,
    force_download = FALSE,
    exclude_first_last = NULL,
    exclude_wear_below = NULL,
    csv_start_row = NULL,
    csv_txyz = NULL,
    csv_txyz_idxs = NULL,
    csv_date_format = NULL,
    calibration_stdtol_min = NULL,
    plot_activity = FALSE,
    cache_classifier = FALSE,
    verbose = TRUE
) {


  args = NULL
  assertthat::assert_that(
    is.null(sample_rate) || assertthat::is.count(sample_rate)
  )
  if (!is.null(sample_rate)) {
    args = c(args, paste0("--sample-rate=", sample_rate))
  }


  assertthat::assert_that(
    null_or_logical(no_hmm),
    null_or_logical(single_sleep_block),
    null_or_logical(force_download),
    null_or_logical(plot_activity),
    null_or_logical(cache_classifier),
    null_or_logical(verbose)
  )
  args = c(
    args,
    if (null_or_true(no_hmm)) "--no-hmm",
    if (null_or_true(single_sleep_block)) "--single-sleep-block",
    if (null_or_true(force_download)) "--force-download",
    if (null_or_true(plot_activity)) "--plot-activity",
    if (!is.null(verbose) && !verbose) "--quiet",
    if (null_or_true(cache_classifier)) "--cache-classifier"
  )

  if (!is.null(exclude_first_last)) {
    exclude_first_last = match.arg(exclude_first_last,
                                   choices = c("first","last","both"),
                                   several.ok = FALSE)
    exclude_first_last = paste0("--exclude-first-last=", exclude_first_last)
    args = c(args,
             exclude_first_last)
  }

  assertthat::assert_that(
    null_or_string(outdir)
  )
  outdir = path.expand(outdir)
  outdir = normalizePath(outdir, winslash = "/", mustWork = FALSE)
  args = c(args, paste0("--outdir=", outdir))


  assertthat::assert_that(
    null_or_string(require_sleep_above),
    null_or_string(exclude_wear_below),
    null_or_string(csv_date_format),
    null_or_string(classifier)
  )
  if (!is.null(require_sleep_above)) {
    require_sleep_above = shQuote(require_sleep_above)
    require_sleep_above = paste0("--require-sleep-above=", require_sleep_above)
    args = c(args, require_sleep_above)
  }

  if (!is.null(classifier)) {
    classifier = paste0("--classifier=", classifier)
    args = c(args, classifier)
  }

  if (!is.null(pytorch_device)) {
    assertthat::assert_that(
      assertthat::is.string(pytorch_device)
    )
    # pytorch_device = match.arg(pytorch_device,
    #                            choices = c("cpu", "cuda:0", "mps"),
    #                            several.ok = FALSE)
    pytorch_device = shQuote(pytorch_device)
    args = c(args, paste0("--pytorch-device=", pytorch_device))
  }

  if (!is.null(exclude_wear_below)) {
    exclude_wear_below = shQuote(exclude_wear_below)
    exclude_wear_below = paste0("--require-sleep-above=", exclude_wear_below)
    args = c(args, exclude_wear_below)
  }

  if (!is.null(csv_date_format)) {
    csv_date_format = shQuote(csv_date_format)
    csv_date_format = paste0("--csv-date-format=", csv_date_format)
    args = c(args, csv_date_format)
  }


  assertthat::assert_that(
    null_or_count(csv_start_row)
  )
  if (!is.null(csv_start_row)) {
    csv_start_row = paste0("--csv-start-row=", csv_start_row)
    args = c(args, csv_start_row)
  }

  if (!is.null(csv_txyz)) {
    csv_txyz = paste(csv_txyz, collapse = ",")
    csv_txyz = shQuote(csv_txyz)
    args = c(args, paste0("--csv-txyz=", csv_txyz))
  }

  if (!is.null(csv_txyz_idxs)) {
    csv_txyz_idxs = paste(csv_txyz_idxs, collapse = ",")
    csv_txyz_idxs = shQuote(csv_txyz_idxs)
    args = c(args, paste0("--csv-txyz-idxs=", csv_txyz_idxs))
  }

  assertthat::assert_that(
    is.null(calibration_stdtol_min) || is.numeric(calibration_stdtol_min)
  )

  if (!is.null(calibration_stdtol_min)) {
    args = c(args, paste0("--calibration-stdtol-min=", calibration_stdtol_min))
  }

  assertthat::assert_that(
    is.null(model_path) || assertthat::is.readable(model_path)
  )
  if (!is.null(model_path)) {
    model_path = path.expand(model_path)
    model_path = normalizePath(model_path, winslash = "/")
    args = c(args, paste0("--model-repo-path=", model_path))
  }

  ac = reticulate::import("actinet.actinet")
  resolve_path = ac$resolve_path

  file = transform_data_to_files(file = file, verbose = verbose)
  remove_file = attr(file, "remove_file")
  if (length(file) == 1 &&
      !is.null(remove_file) &&
      remove_file) {
    on.exit({
      file.remove(file)
    }, add = TRUE)
  }
  assertthat::assert_that(
    sapply(file, assertthat::is.readable)
  )
  file = normalizePath(path.expand(file), winslash = "/")
  args = c(args, file)

  out = reticulate::uv_run_tool(
    "actinet",
    args = args,
    python_version = "3.10"
  )
  bn = as.character(resolve_path(file)[[2]])
  real_outdir = file.path(outdir, bn, fsep = "/")
  outfiles = file.path(
    real_outdir,
    c(
      paste0(bn, "-timeSeries.csv.gz"),
      paste0(bn, "-outputSummary.json"),
      paste0(bn, "-Daily.csv.gz")
    ), fsep = "/"
  )
  results = list(
    outdir_passed = outdir,
    outdir = real_outdir,
    outfiles = outfiles
  )
  return(results)

}

transform_data_to_files = function(file, verbose = TRUE) {
  if (verbose) {
    message("Checking Data")
  }

  # single df
  if (is.data.frame(file)) {
    if (verbose) {
      message("Writing file to CSV...")
    }
    tfile = tempfile(fileext = ".csv")
    file = sc_write_csv(data = file, path = tfile)
    attr(file, "remove_file") = TRUE
  }

  if (
    # a list of files
    (is.character(file) &&
     all(sapply(file, assertthat::is.readable))) ||
    # could be list of dfs
    is.list(file) ) {
    file = vapply(file, FUN.VALUE = character(1), FUN = function(f) {
      if (is.data.frame(f)) {
        if (verbose) {
          message("Writing file to CSV...")
        }
        tfile = tempfile(fileext = ".csv")
        f = sc_write_csv(data = f, path = tfile)
        attr(f, "remove_file") = TRUE
      }
      f
    })
    names(file) = file
  }
  return(file)
}

