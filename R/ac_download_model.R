ac_classifier = function(classifier) {
  switch(
    classifier,
    "walmsley" = "ssl-ukb-c24-rw-30s-20260128",
    "willetts" = "ssl-ukb-c24-mw-30s-20260128"
  )
}
ac_model_md5 = function(classifier) {
  switch(
    classifier,
    "walmsley" = "a829041ba84b18084b4b2897fb1b36a6",
    "willetts" = "59a9492b50ee922c7a31f88888c5f14b"
  )
}


check_versions = function(x) {
  ac = reticulate::import("actinet.__init__", convert = TRUE)
  classifiers = ac$`__classifiers__`
  stopifnot(ac_classifier("walmsley") == classifiers$walmsley$version)
  stopifnot(ac_classifier("willetts") == classifiers$willetts$version)
  stopifnot(ac_model_md5("walmsley") == classifiers$walmsley$md5)
  stopifnot(ac_model_md5("willetts") == classifiers$willetts$md5)
}



#' Load Actinet Model
#'
#' @param classifier type of the model: either walmsley or willetts
#' @param check_md5 Do a MD5 checksum on the file
#' @param force_download force a download of the model, even if the file
#' exists
#' @param model_path the file path to the model.  If on disk, this can be
#' re-used and not re-downloaded.  If `NULL`, will download to the
#' temporary directory
#' @param as_python Keep model object as a python object
#'
#' @return A model from Python.  `ac_download_model` returns a model file path.
#' @export
ac_load_model = function(
    classifier = c("walmsley", "willetts"),
    model_path = NULL,
    check_md5 = TRUE,
    force_download = FALSE,
    as_python = TRUE
) {

  classifier = match.arg(classifier, choices = c("walmsley", "willetts"))
  ac = reticulate::import("actinet.actinet", convert = !as_python)
  if (is.null(model_path)) {
    model_path = file.path(
      tempdir(),
      paste0(classifier, ".joblib.lzma")
    )
  } else {
    model_path = path.expand(model_path)
  }
  model = ac$load_classifier(
    model_repo_path = model_path,
    classifier = classifier,
    force_download = force_download)
  model
}

#' @export
#' @rdname ac_load_model
ac_model_filename = function(
    classifier = c("walmsley", "willetts")
) {
  classifier = match.arg(classifier, choices = c("walmsley", "willetts"))
  classifier = ac_classifier(classifier)
  paste0(classifier, ".joblib.lzma")
}

#' @export
#' @rdname ac_load_model
#' @param ... for `ac_download_model`, additional arguments to pass to
#' [curl::curl_download()]
ac_download_model = function(
    model_path,
    classifier = c("walmsley", "willetts"),
    check_md5 = TRUE,
    ...
) {
  classifier = match.arg(classifier, choices = c("walmsley", "willetts"))
  model_filename = ac_model_filename(classifier = classifier)
  model_md5 = ac_model_md5(classifier)
  base_url = "https://wearables-files.ndph.ox.ac.uk/files/models/actinet/"
  url = paste0(base_url, model_filename)
  curl::curl_download(url = url, destfile = model_path)
  if (check_md5) {
    file_md5 = tools::md5sum(model_path)
    stopifnot(file_md5 == model_md5)
  }
  return(model_path)
}
