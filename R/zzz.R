.onLoad <- function(libname, pkgname) {
  reticulate::py_require("actinet==0.7.2", python_version = "3.10")
}
