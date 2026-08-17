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

actinet_python_packages = function(os_type = .Platform$OS.type) {
  packages = "actinet==0.7.2"

  # Pin this pair only on Windows, where the latest torch release can fail to
  # load c10.dll in the GitHub Actions runner. Do not constrain macOS so uv can
  # select the appropriate arm64 wheel for Apple Silicon.
  if (identical(os_type, "windows")) {
    packages = c(
      packages,
      "torch==2.8.0",
      "torchvision==0.23.0"
    )
  }

  packages
}
