% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/germline.R
\name{repGermline}
\alias{repGermline}
\title{This function creates germlines for clonal lineages. B cell clonal lineage represents a set of B cells
that presumably have a common origin (arising from the same VDJ rearrangement event) and a common ancestor.
Each clonal lineage has its own germline sequence that represents the ancestral sequence
for each BCR in clonal lineage. In other words, germline sequence is a sequence of B-cells immediately
after VDJ recombination, before B-cell maturation and hypermutation process. Germline sequence is useful
for assessing the degree of mutation and maturity of the repertoire.}
\usage{
repGermline(.data, species, min_nuc_outside_cdr3, ref_only_first)
}
\arguments{
\item{.data}{The data to be processed. Can be \link{data.frame}, \link{data.table}
or a list of these objects.

It must have columns in the immunarch compatible format \link{immunarch_data_format}.}

\item{species}{Species from which the data was acquired. Available options:
"HomoSapiens" (default), "MusMusculus", "BosTaurus", "CamelusDromedarius",
"CanisLupusFamiliaris", "DanioRerio", "MacacaMulatta", "MusMusculusDomesticus",
"MusMusculusCastaneus", "MusMusculusMolossinus", "MusMusculusMusculus", "MusSpretus",
"OncorhynchusMykiss", "OrnithorhynchusAnatinus", "OryctolagusCuniculus", "RattusNorvegicus",
"SusScrofa".}

\item{min_nuc_outside_cdr3}{This parameter sets how many nucleotides should have V or J chain
outside of CDR3 to be considered good for further alignment.}

\item{ref_only_first}{This parameter, if TRUE, means to take only first sequence from reference
for each allele name; if FALSE, all sequences will be taken, and output table will
increase in size as a result.}
}
\value{
Data with added columns V.first.allele, J.first.allele (with first alleles of V and J genes),
V.sequence, J.sequence (with V and J reference sequences),
Germline.sequence (with combined germline sequence)
}
\description{
Creates germlines for clonal lineages
}
\examples{

data(bcrdata)

bcrdata$data \%>\%
  repGermline()
}
\concept{germline}