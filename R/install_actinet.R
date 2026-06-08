#' Check the `actinet` Python Module
#'
#'
#' @return A logical value indicating whether the `actinet` Python module is available.
#' @export
#' @rdname actinet_setup
#' @examples
#' \donttest{
#'   if (have_actinet()) {
#'      actinet_version()
#'   }
#' }
have_actinet = function() {
  reticulate::py_module_available("actinet")
}

#' @export
#' @rdname actinet_setup
actinet_check = function() {
  step_version = try({
    actinet_version()
  }, silent = TRUE)
  have_actinet() && !inherits(step_version, "try-error") &&
    length(step_version) > 0 && package_version(step_version) >= package_version("0.7.2")
}


module_version = function(module = "numpy") {
  assertthat::is.scalar(module)
  if (!reticulate::py_module_available(module)) {
    stop(paste0(module, " is not installed!"))
  }
  df = reticulate::py_list_packages()
  df$version[df$package == module]
}


#' @export
#' @rdname actinet_setup
actinet_version = function() {
  module_version("actinet")
}
