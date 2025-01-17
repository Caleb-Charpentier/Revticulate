% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/findRev.R
\name{findRev}
\alias{findRev}
\title{Searches for the RevBayes executable}
\usage{
findRev(parentDirectory = "~")
}
\arguments{
\item{parentDirectory}{Parent directory to recursively search for the RevBayes executable. Default is the user's root directory ('~'). Because many sub-directories likely exist within the root directory, the search time will greatly decrease by providing a lower level directory path to the RevBayes executable.}
}
\value{
getPaths: character. Located path to RevBayes executable.
}
\description{
Recursively searches the users machine for the RevBayes executable and returns a vector of possible paths
}
\examples{
\dontrun{
findRev()
}
\dontrun{
findRev("C://Users/caleb/")
}

}
