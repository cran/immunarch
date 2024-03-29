#' Function for assigning clusters based on sequences similarity
#'
#' @concept seq_cluster
#'
#' @importFrom purrr map map_lgl map_chr map2 map2_chr map_df map2_lgl pmap map2_df
#' @importFrom magrittr %>% %<>%
#' @importFrom reshape2 melt
#' @importFrom dplyr group_by mutate ungroup select cur_group_id left_join
#' @importFrom igraph graph_from_data_frame clusters
#' @importFrom reshape2 melt
#' @importFrom tibble rownames_to_column
#' @importFrom glue glue
#'
#' @description Graph clustering based on distances between sequences
#'
#' @usage
#'
#' seqCluster(.data, .dist, .perc_similarity, .nt_similarity, .fixed_threshold)
#'
#' @param .data The data which was used to caluculate .dist object. Can be \link{data.frame},
#' \link{data.table}, or a list of these objects.
#'
#' Every object must have columns in the immunarch compatible format \link{immunarch_data_format}
#'
#' @param .dist List of distance objects produced with \link{seqDist} function.
#'
#' @param .perc_similarity   Numeric value between 0 and 1 specifying the maximum acceptable weight of an edge in a graph.
#'                           This threshold depends on the length of sequences.
#' @param .nt_similarity     Numeric between 0-sequence length specifying
#'                           the threshold of allowing a 1 in n nucleotides mismatch in sequencies.
#' @param .fixed_threshold   Numeric specifying the threshold on the maximum weight of an edge in a graph.
#'
#' @return
#'
#' Immdata data format object. Same as .data, but with extra 'Cluster' column with clusters assigned.
#'
#' @examples
#'
#' data(immdata)
#' # In this example, we will use only 2 samples with 500 clonotypes in each for time saving
#' input_data <- lapply(immdata$data[1:2], head, 500)
#' dist_result <- seqDist(input_data)
#' cluster_result <- seqCluster(input_data, dist_result, .fixed_threshold = 1)
#' @export seqCluster

seqCluster <- function(.data, .dist, .perc_similarity, .nt_similarity, .fixed_threshold = 10) {
  grouping_cols <- attr(.dist, "group_by")
  matching_col <- attr(.dist, "col")
  trimmed <- attr(.dist, "trimmed")
  if (length(.data) != length(.dist)) {
    stop(".data and .dist lengths do not match!")
  }
  if (all(!(names(.data) %in% names(.dist)))) {
    stop(".data and .dist names do not match!")
  } else {
    .dist <- .dist[order(match(names(.dist), names(.data)))] # This one cause removing of all attributes except names!
  }
  if (!(matching_col %in% colnames(.data[[1]]))) {
    stop("There is no ", matching_col, " in .data!")
  }
  thresh_cond <- c(missing(.perc_similarity), missing(.nt_similarity), missing(.fixed_threshold))
  if (all(thresh_cond)) {
    stop("Please, provide .perc_similarity, .nt_similarity or .fixed_threshold value")
  }
  if (sum(thresh_cond) == 1) {
    stop("Please, provide only one argument: .perc_similarity, .nt_similarity or .fixed_threshold value")
  }

  nt_similarity_fun <- function(x, t = .nt_similarity) {
    (x / t)
  }
  perc_similarity_fun <- function(x, t = .perc_similarity) {
    x * (1 - t)
  }
  fixed_threshold_fun <- function(x, t = .fixed_threshold) {
    return(rep(t, times = length(x)))
  }
  if (!missing(.nt_similarity)) {
    .threshold_fun <- nt_similarity_fun
  }
  if (!missing(.perc_similarity)) {
    .threshold_fun <- perc_similarity_fun
  }
  if (!missing(.fixed_threshold)) {
    .threshold_fun <- fixed_threshold_fun
  }

  graph_clustering <- function(dist_list, threshold_fun) {
    seq_labels <- map(dist_list, ~ attr(.x, "Labels"))
    singleseq_flag <- map_lgl(seq_labels, ~ length(.x) == 1)
    seq_length <- map(seq_labels, ~ nchar(.x))
    threshold <- map(seq_length, ~ .x %>% threshold_fun())
    group_values <- map_dfr(dist_list, ~ attr(.x, "group_values"))
    if (all(is.na(grouping_cols))) {
      protocluster_names <- map_chr(seq_labels, 1)
      result_single <- data.frame(
        Sequence = unlist(seq_labels[singleseq_flag]),
        Cluster = paste0(
          protocluster_names[singleseq_flag],
          "_length_",
          seq_length[singleseq_flag],
          "_cluster_1"
        )
      )
    } else {
      protocluster_names <- group_values %>%
        unite(col = grouping_cols, sep = "/") %>%
        pull(grouping_cols)
      result_single <- data.frame(
        Sequence = unlist(seq_labels[singleseq_flag]),
        Cluster = paste0(
          protocluster_names[singleseq_flag],
          "_length_",
          seq_length[singleseq_flag]
        )
      ) %>% cbind(group_values[singleseq_flag, ])
    }
    # ^if no grouping variables in data, sequences are IDs for clusters
    multiseq_dist <- dist_list[!singleseq_flag]
    mat_dist <- map2(multiseq_dist, threshold[!singleseq_flag], ~ as.matrix(.x) %>%
      apply(., 1, function(x, t) {
        ifelse(x > t, NA, x)
      }, .y))
    seq_clusters <- map(mat_dist, ~ melt(.x, na.rm = TRUE) %>%
      graph_from_data_frame() %>%
      clusters() %>%
      .$membership %>%
      melt() %>%
      suppressWarnings())
    result_multi <- seq_clusters %>%
      map2(., seq_length[!singleseq_flag], ~ .x %>%
        mutate(
          length_value = map_chr(.y, ~ ifelse(all(.x == .x[1]),
            yes = .x[1],
            no = glue("range_{min(.x)}:{max(.x)}")
          ))
        )) %>%
      map2(., protocluster_names[!singleseq_flag], ~ rownames_to_column(.x, var = "Sequence") %>%
        group_by(value, length_value) %>%
        mutate(Cluster = paste0(.y, "_length_", length_value, "_cluster_", cur_group_id())) %>%
        ungroup() %>%
        select(Sequence, Cluster))
    if (!all(is.na(grouping_cols))) {
      result_multi %<>% map2_df(., pmap(group_values, data.frame)[!singleseq_flag], ~ cbind(.x, .y))
      res <- rbind(result_single, result_multi)
      res[grouping_cols] <- str_split(
        str_split(res[["Cluster"]],
          pattern = "_", simplify = TRUE
        )[, 1],
        pattern = "/", simplify = TRUE
      )[, seq_along(grouping_cols)]
    } else {
      result_multi %<>% map_df(., ~.x)
      res <- rbind(result_single, result_multi)
      colnames(res) <- c(matching_col, "Cluster")
    }
    colnames(res)[1] <- matching_col
    return(res)
  }
  clusters <- map(.dist, ~ graph_clustering(.x, threshold_fun = .threshold_fun))
  if (!all(map2_lgl(clusters, .data, ~ nrow(.x) == nrow(.y)))) {
    warning("Number of sequence provided in .data and .dist are not matching!")
  }
  # supress messages because join spams about joining by matching_col is done
  temp_data <- .data
  if (trimmed) {
    for (colname in grouping_cols) {
      temp_data <- add_column_with_first_gene(temp_data, colname)
    }
  }
  joined_data <- map2(temp_data, clusters, ~ left_join(.x, .y) %>% suppressMessages())
  clusters_cols <- map(joined_data, "Cluster")
  result_data <- map2(.data, clusters_cols, ~ cbind(.x, "Cluster" = .y))
  return(result_data)
}
