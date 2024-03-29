% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/vis.R
\name{vis_heatmap2}
\alias{vis_heatmap2}
\title{Visualisation of matrices using pheatmap-based heatmaps}
\usage{
vis_heatmap2(
  .data,
  .meta = NA,
  .by = NA,
  .title = NA,
  .color = colorRampPalette(c("#67001f", "#d6604d", "#f7f7f7", "#4393c3",
    "#053061"))(1024),
  ...
)
}
\arguments{
\item{.data}{Input matrix. Column names and row names (if presented) will be used as names for labs.}

\item{.meta}{A metadata object. An R dataframe with sample names and their properties,
such as age, serostatus or hla.}

\item{.by}{Set NA if you want to plot samples without grouping.}

\item{.title}{The text for the plot's title (same as the "main" argument in \link[pheatmap]{pheatmap}).}

\item{.color}{A vector specifying the colors (same as the "color" argument in \link[pheatmap]{pheatmap}).
Pass NA to use the default pheatmap colors.}

\item{...}{Other arguments for the \link[pheatmap]{pheatmap} function.}
}
\value{
A pheatmap object.
}
\description{
Visualise matrices with the functions based on the \link[pheatmap]{pheatmap}
package with minimum amount of arguments.
}
\examples{
data(immdata)
ov <- repOverlap(immdata$data)
vis_heatmap2(ov)
}
\seealso{
\link{vis}, \link{repOverlap}
}
\concept{vis}
