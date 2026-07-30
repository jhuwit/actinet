#' Minute Level `actinet` output
#'
#' @param ... arguments to pass to [actinet::actinet]
#'
#' @returns A minute-level `data.frame`
#' @export
acti_net = function(...) {
  actinet(...)$data_minute
}

#' @rdname acti_net
#' @export
py_acti_net = function(...) {
  py_actinet(...)$data_minute
}

