% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tools.R
\name{bunch_translate}
\alias{bunch_translate}
\alias{translate_bunch}
\title{Nucleotide to amino acid sequence translation}
\usage{
bunch_translate(.seq, .two.way = TRUE)
}
\arguments{
\item{.seq}{Vector or list of strings.}

\item{.two.way}{Logical. If TRUE (default) then translate from the both ends (like MIXCR).}
}
\value{
Character vector of translated input sequences.
}
\description{
Nucleotide to amino acid sequence translation
}
\examples{
data(immdata)
head(bunch_translate(immdata$data[[1]]$CDR3.nt))
}
\concept{preprocessing}
