#' Command for `py_require` for `actinet`
#'
#' @param ... arguments to pass to [reticulate::py_require()]
#'
#' @returns A logical value indicating whether the package is available.
#' @export
py_require_actinet = function(...) {
  reticulate::py_require(
    actinet_python_packages(),
    python_version = "3.10",
    ...)
}

actinet_python_packages = function() {
  c(
    "actinet==0.7.2",
    "torch>=1.13,<3",
    "torchvision>=0.14,<1"
  )
}
