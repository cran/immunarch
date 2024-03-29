% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/diversity.R
\name{repDiversity}
\alias{repDiversity}
\alias{chao1}
\alias{hill_numbers}
\alias{diversity_eco}
\alias{gini_simpson}
\alias{inverse_simpson}
\alias{gini_coef}
\alias{rarefaction}
\title{The main function for immune repertoire diversity estimation}
\usage{
repDiversity(
  .data,
  .method = "chao1",
  .col = "aa",
  .max.q = 6,
  .min.q = 1,
  .q = 5,
  .step = NA,
  .quantile = c(0.025, 0.975),
  .extrapolation = NA,
  .perc = 50,
  .norm = TRUE,
  .verbose = TRUE,
  .do.norm = NA,
  .laplace = 0
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

\item{.method}{Picks a method used for estimation out of a following list: chao1,
hill, div, gini.simp, inv.simp, gini, raref, d50, dxx.}

\item{.col}{A string that specifies the column(s) to be processed. Pass one of the
following strings, separated by the plus sign: "nt" for nucleotide sequences,
"aa" for amino acid sequences, "v" for V gene segments, "j" for J gene segments. E.g.,
pass "aa+v" to compute diversity estimations on CDR3 amino acid sequences paired with V gene segments, i.e.,
in this case a unique clonotype is a pair of CDR3 amino acid and V gene segment.
Clonal counts of equal clonotypes will be summed up.}

\item{.max.q}{The max hill number to calculate (default: 5).}

\item{.min.q}{Function calculates several hill numbers. Set the min (default: 1).}

\item{.q}{q-parameter for the Diversity index.}

\item{.step}{Rarefaction step's size.}

\item{.quantile}{Numeric vector with quantiles for confidence intervals.}

\item{.extrapolation}{An integer. An upper limit for the number of clones to extrapolate to.
Pass 0 (zero) to turn extrapolation subroutines off.}

\item{.perc}{Set the percent to dXX index measurement.}

\item{.norm}{Normalises rarefaction curves.}

\item{.verbose}{If TRUE then outputs progress.}

\item{.do.norm}{One of the three values - NA, TRUE or FALSE. If NA then checks for distrubution (sum(.data) == 1)
and normalises if needed with the given laplace correction value. if TRUE then does normalisation and laplace
correction. If FALSE then doesn't do neither normalisaton nor laplace correction.}

\item{.laplace}{A numeric value, which is used as a pseudocount for Laplace
smoothing.}
}
\value{
div, gini, gini.simp, inv.simp, raref return numeric vector of length 1
with value.

chao1 returns 4 values: estimated number of species, standart deviation of
this number and two 95% confidence intervals for the species number.

hill returns a vector of specified length \code{.max.q - .min.q}

For most methods, if input data is a single immune repertoire, then the function returns a numeric vector
with diversity statistics.

Otherwise, it returns a numeric matrix with diversity statistics for all input repertoires.

For Chao1 the function returns a matrix with diversity estimations.

For rarefaction the function returns either a matrix with diversity estimatinos
on different step of the simulaiton process or a list with such matrices.
}
\description{
This is a utility function to estimate the diversity of species or objects in the given distribution.

Note: functions will check if .data is a distribution of a random variable (sum == 1) or not.
To force normalisation and / or to prevent this, set .do.norm to TRUE (do normalisation)
or FALSE (don't do normalisation), respectively.
}
\details{
- True diversity, or the effective number of types, refers to the number
of equally-abundant types needed for the average proportional abundance
of the types to equal that observed in the dataset of interest
where all types may not be equally abundant.

- Inverse Simpson index is the effective number of types that is obtained when
the weighted arithmetic mean is used to quantify average
proportional abundance of types in the dataset of interest.

- The Gini coefficient measures the inequality among values
of a frequency distribution (for example levels of income). A Gini coefficient of zero
expresses perfect equality, where all values are the same (for example, where everyone
has the same income). A Gini coefficient of one (or 100 percents ) expresses maximal inequality
among values (for example where only one person has all the income).

- The Gini-Simpson index is the probability of interspecific encounter, i.e., probability that two entities
represent different types.

- Chao1 estimator is a nonparameteric asymptotic estimator of species richness (number of species in a population).

- Rarefaction is a technique to assess species richness from the results of sampling through extrapolation.

- Hill numbers are a mathematically  unified family of  diversity indices (differing among themselves
only by an exponent q).

- d50 is a recently developed immune diversity estimate. It calculates the minimum number of distinct clonotypes
amounting to greater than or equal to 50 percent of a total of sequencing reads obtained
following amplification and sequencing

- dXX is a similar to d50 index where XX corresponds to desirable percent of total sequencing reads.
}
\examples{
data(immdata)

# Make data smaller for testing purposes
immdata$data <- top(immdata$data, 4000)

# chao1
repDiversity(.data = immdata$data, .method = "chao1") \%>\% vis()

# Hill numbers
repDiversity(
  .data = immdata$data, .method = "hill", .max.q = 6,
  .min.q = 1, .do.norm = NA, .laplace = 0
) \%>\% vis()

# diversity
repDiversity(.data = immdata$data, .method = "div", .q = 5, .do.norm = NA, .laplace = 0) \%>\%
  vis()

# Gini-Simpson
repDiversity(.data = immdata$data, .method = "gini.simp", .q = 5, .do.norm = NA, .laplace = 0) \%>\%
  vis()

# inverse Simpson
repDiversity(.data = immdata$data, .method = "inv.simp", .do.norm = NA, .laplace = 0) \%>\% vis()

# Gini coefficient
repDiversity(.data = immdata$data, .method = "gini", .do.norm = NA, .laplace = 0)

# d50
repDiversity(.data = immdata$data, .method = "d50") \%>\% vis()
}
\seealso{
\link{repOverlap}, \link{entropy}, \link{repClonality}
Rarefaction wiki
\url{https://en.wikipedia.org/wiki/Rarefaction_(ecology)}
Hill numbers paper
\url{https://www.uvm.edu/~ngotelli/manuscriptpdfs/ChaoHill.pdf}
Diversity wiki
\url{https://en.wikipedia.org/wiki/Measurement_of_biodiversity}
}
\concept{diversity}
