#' Submit input to RevBayes and return output
#'
#' Submits input to the RevBayes executable and returns output to R in string format. If coerce = TRUE, the function coerRev()
#'    will attempt to coerce output to a similar R object.
#'
#' @param ... String input to send to RevBayes.
#' @param coerce If TRUE, attempts to coerce output to an R object. If FALSE, output
#'     will remain in String format. Default is FALSE.
#' @param path Path to the RevBayes executable. Default is Sys.getEnv("RevBayesPath"), which is created with initRev().
#' @param viewCode If TRUE, the input and output in the temporary file used to interact
#'     with RevBayes will be displayed in the viewing pane. This option may be useful for
#'     diagnosing code errors.
#' @param use_wd If TRUE, sets the working directory in the temporary RevBayes session
#'     to the working directory of the active R session. Default is TRUE.
#' @param knit Argument used to manage output formatting for knitRev(). This argument
#'             should generally be ignored by the user.
#' @param timeout Determines how long the system2() call should wait before timing out (seconds). Default is 5.
#'
#' @return out: character. String formatted output from RevBayes
#' @return coercedOut: type varies. R object formatted output from RevBayes. Object type varies according to Rev output (Ex: numeric vector or ape::Phylo object)
#'
#' @examples
#' \dontrun{
#' callRev("2^3")
#' callRev("2^3", coerce = FALSE, viewcode = TRUE)
#'}
#'@import utils
#'@import stringr
#'
#'@export
#'

callRev <- function (..., coerce = FALSE, path = Sys.getenv("RevBayesPath"), viewCode = FALSE,
                     use_wd = TRUE, knit = FALSE, timeout = 5){

  argu <- c(...)

  for(file in list.files(Sys.getenv("RevTemps"), full.names = TRUE))
    unlink(file)

  if (knit) {
    clumpBrackets <- function(stringVector) {
      openBraces <- stringr::str_count(stringVector, "\\{")
      closedBraces <- stringr::str_count(stringVector,
                                         "\\}")
      if (all(openBraces == 0)) {
        return(stringVector)
      }
      allBraces <- openBraces - closedBraces
      startsStops <- which(allBraces != 0)
      startStopVals <- allBraces[startsStops]
      stopIndexes <- c()
      net <- startStopVals[1]
      for (i in 2:length(startStopVals)) {
        net <- net + startStopVals[i]
        if (net == 0) {
          stopIndexes <- c(stopIndexes, i)
        }
      }
      finalStopVals <- startsStops[stopIndexes]
      finalStartVals <- c(startsStops[1], finalStopVals +
                            1)
      finalStartVals <- finalStartVals[-c(length(finalStartVals))]
      finalStartStopVals <- list(finalStartVals, finalStopVals)
      finalVector <- c(stringVector[which(1:length(stringVector) <
                                            startsStops[1])])
      for (i in 1:length(finalStartStopVals[[1]])) {
        start <- finalStartStopVals[[1]][i]
        stop <- finalStartStopVals[[2]][i]
        finalVector <- c(finalVector, stringr::str_c(stringVector[start:stop],
                                                     collapse = "\n"))
      }
      highestStopValue <- finalStopVals[length(finalStopVals)]
      if (highestStopValue < length(stringVector)) {
        finalVector <- c(finalVector, stringVector[c((highestStopValue +
                                                        1):length(stringVector))])
      }
      finalVector <- stringr::str_c("\n", finalVector,
                                    sep = "")
      return(finalVector)
    }
    if (stringr::str_c(..., collapse = "") == "") {
      return("")
    }
    argu <- clumpBrackets(c(...))
    argu <- stringr::str_squish(argu)
    argu <- argu[which(argu != "")]

  }

  argu <- c(argu)

  if (use_wd) {
    wd <- stringr::str_replace_all(normalizePath(getwd()),
                                   pattern = "\\\\", "//")
    argu <- c("setwd(\"" %+% wd %+% "\")", argu)
  }

  tf <- tempfile(pattern = "file", tmpdir = paste(Sys.getenv("RevTemps"),
                                                  "/", sep = ""), fileext = ".rev")

  tf <- suppressWarnings((gsub(pattern = "\\\\", "/", tf)))

  fopen <- file(tf)
  ret <- unlist(argu)
  writeLines(ret, fopen, sep = "\n")
  out <- system2(path, args = c(tf), stdout = TRUE, timeout=timeout)
  out <- out[-c(1:13, length(out) - 1, length(out))]
  cat("Input:\n -->  " %+% ret %+% "\n//", file = tf,
      sep = "\n", append = FALSE)
  cat("Output:\n -->  " %+% out %+% "\n//", file = tf,
      sep = "\n", append = TRUE)
  if (viewCode == TRUE) {
    viewOut <- stringr::str_view_all(readLines(tf), pattern = "Error|error|Input:|Output:")
    utils::capture.output(viewOut)
  }
  close(fopen)

  for(file in list.files(Sys.getenv("RevTemps"), full.names = TRUE))
    unlink(file)

  if (coerce == FALSE) {
    return(out)
  }

  out <- stringr::str_c(out, collapse = "\n")

  if (coerce) {
    coercedOut <- coerceRev(out)
  }
  unlink(tf)
  return(coercedOut)
}
