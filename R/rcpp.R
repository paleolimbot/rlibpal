
#' @useDynLib rlibpal
#' @importFrom Rcpp sourceCpp
NULL

.onUnload <- function (libpath) {
  library.dynam.unload("rlibpal", libpath)
}
