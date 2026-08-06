#' Command for `py_require` for `actinet`
#'
#' @param ... arguments to pass to [reticulate::py_require()]
#'
#' @returns A logical value indicating whether the package is available.
#' @export
py_require_actinet = function(...) {
  reticulate::py_require("actinet==0.7.2", python_version = "3.10",
                         ...)
}
