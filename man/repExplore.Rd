% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/explore.R
\name{repExplore}
\alias{repExplore}
\title{Main function for exploratory data analysis: compute the distribution of lengths, clones, etc.}
\usage{
repExplore(
  .data,
  .method = c("volume", "count", "len", "clones"),
  .col = c("nt", "aa"),
  .coding = TRUE
)
}
\arguments{
\item{.data}{The data to be processed. Can be \link{data.frame},
\link{data.table}, or a list of these objects.

Every object must have columns in the immunarch compatible format.
\link{immunarch_data_format}

Competent users may provide advanced data representations:
DBI database connections, Apache Spark DataFrame from \link{copy_to} or a list
of these objects. They are supported with the same limitations as basic objects.

Note: each connection must represent a separate repertoire.}

\item{.method}{A string that specifies the method of analysis. It can be
either "volume", "count", "len" or "clones".

When .method is set to "volume" the repExplore calculates the number of unique
clonotypes in the input data.

When .method is set to "count" the repExplore calculates the distribution of
clonotype abundances, i.e., how frequent receptors with different abundances are.

When .method is set to "len" the repExplore calculates the distribution of
CDR3 sequence lengths.

When .method is set to "clones" the repExplore returns the number of clones (i.e., cells)
per input repertoire.}

\item{.col}{A string that specifies the column to be processed. Pass "nt" for
nucleotide sequence or "aa" for amino acid sequence.}

\item{.coding}{If \code{TRUE}, then only coding sequences will be analysed.}
}
\value{
If input data is a single immune repertoire, then the function returns a numeric vector
with exploratory analysis statistics.

Otherwise, it returns a numeric matrix with exploratory analysis statistics for all input repertoires.
}
\description{
The \code{repExplore} function calculates the basic statistics of
repertoire: the number of unique immune receptor clonotypes, their relative abundances,
and sequence length distribution across the input dataset.
}
\examples{
data(immdata)

# Calculate statistics and generate a visual output with vis()
repExplore(immdata$data, .method = "volume") \%>\% vis()

repExplore(immdata$data, .method = "count") \%>\% vis()

repExplore(immdata$data, .method = "len") \%>\% vis()
}
\seealso{
\link{vis.immunr_exp_vol}
}
\concept{explore}
