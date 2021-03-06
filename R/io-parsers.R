parse_repertoire <- function(.filename, .mode, .nuc.seq, .aa.seq, .count,
                             .vgenes, .jgenes, .dgenes,
                             .vend, .jstart, .dstart, .dend,
                             .vd.insertions, .dj.insertions, .total.insertions,
                             .skip = 0, .sep = "\t", .add = NA) {
  .nuc.seq <- .make_names(.nuc.seq)
  .aa.seq <- .make_names(.aa.seq)
  .count <- .make_names(.count)
  .vgenes <- .make_names(.vgenes)
  .jgenes <- .make_names(.jgenes)
  .dgenes <- .make_names(.dgenes)
  .vend <- .make_names(.vend)
  .jstart <- .make_names(.jstart)
  .vd.insertions <- .make_names(.vd.insertions)
  .dj.insertions <- .make_names(.dj.insertions)
  .total.insertions <- .make_names(.total.insertions)
  .dstart <- .make_names(.dstart)
  .dend <- .make_names(.dend)
  .add <- .make_names(.add)

  col.classes <- .get_coltypes(.filename, .nuc.seq, .aa.seq, .count,
                               .vgenes, .jgenes, .dgenes,
                               .vend, .jstart, .dstart, .dend,
                               .vd.insertions, .dj.insertions, .total.insertions,
                               .skip = .skip, .sep = "\t", .add
  )

  # IO_REFACTOR
  suppressMessages(df <- readr::read_delim(.filename,
                                           col_names = TRUE,
                                           col_types = col.classes, delim = .sep,
                                           quote = "", escape_double = FALSE,
                                           comment = "", trim_ws = TRUE,
                                           skip = .skip, na = c("", "NA", ".")
  ))
  # suppressMessages(df <- fread(.filename, skip = .skip, data.table = FALSE, na.strings = c("", "NA", ".")))

  names(df) <- tolower(names(df))
  recomb_type <- .which_recomb_type(df[[.vgenes]])

  table.colnames <- names(col.classes)

  df[[.nuc.seq]] <- toupper(df[[.nuc.seq]])

  if (is.na(.aa.seq)) {
    df$CDR3.amino.acid.sequence <- bunch_translate(df[[.nuc.seq]])
    .aa.seq <- "CDR3.amino.acid.sequence"
  }

  if (is.na(.count)) {
    .count <- "Count"
    df$Count <- 1
  }

  df$Proportion <- df[[.count]] / sum(df[[.count]])
  .prop <- "Proportion"

  ins_ok <- FALSE
  if (is.na(.vd.insertions)) {
    .vd.insertions <- "VD.insertions"
    df$VD.insertions <- NA
  }

  if (!(.vd.insertions %in% table.colnames)) {
    .vd.insertions <- "VD.insertions"
    df$VD.insertions <- NA

    if (!is.na(.vend) && !is.na(.dstart)) {
      if (!is.na(recomb_type) && recomb_type == "VDJ") {
        df$VD.insertions <- df[[.dstart]] - df[[.vend]] - 1
        df$VD.insertions[is.na(df[[.dstart]])] <- NA
        df$VD.insertions[is.na(df[[.vend]])] <- NA

        ins_ok <- TRUE
      }
    }
  }

  if (!ins_ok) {
    df$V.end <- NA
    df$D.start <- NA
    df$D.end <- NA
    .vend <- "V.end"
    .dstart <- "D.start"
    .dend <- "D.end"
  }

  ins_ok <- FALSE
  if (is.na(.dj.insertions)) {
    .dj.insertions <- "DJ.insertions"
    df$DJ.insertions <- NA
  }

  if (!(.dj.insertions %in% table.colnames)) {
    .dj.insertions <- "DJ.insertions"
    df$DJ.insertions <- NA

    if (!is.na(.jstart) && !is.na(.dend)) {
      if (!is.na(recomb_type) && recomb_type == "VDJ") {
        df$DJ.insertions <- df[[.jstart]] - df[[.dend]] - 1
        df$DJ.insertions[is.na(df[[.dend]])] <- NA
        df$DJ.insertions[is.na(df[[.jstart]])] <- NA

        ins_ok <- TRUE
      }
    }
  }
  if (!ins_ok) {
    df$J.start <- NA
    df$D.start <- NA
    df$D.end <- NA
    .jstart <- "J.start"
    .dstart <- "D.start"
    .dend <- "D.end"
  }

  ins_ok <- FALSE
  if (is.na(.total.insertions)) {
    .total.insertions <- "Total.insertions"
    df$Total.insertions <- NA
  }

  if (!(.total.insertions %in% table.colnames)) {
    .total.insertions <- "Total.insertions"
    df$Total.insertions <- -1
    if (!is.na(recomb_type)) {
      if (recomb_type == "VJ") {
        df$Total.insertions <- df[[.jstart]] - df[[.vend]] - 1
        df$Total.insertions[df$Total.insertions < 0] <- 0
      } else if (recomb_type == "VDJ") {
        df$Total.insertions <- df[[.vd.insertions]] + df[[.dj.insertions]]
      }
    } else {
      df$Total.insertions <- NA
    }
  }

  vec_names <- c(
    .count, .prop, .nuc.seq, .aa.seq,
    .vgenes, .dgenes, .jgenes,
    .vend, .dstart, .dend, .jstart,
    .total.insertions, .vd.insertions, .dj.insertions
  )
  if (!is.na(.add[1])) {
    vec_names <- c(vec_names, .add)
  }

  df <- df[, vec_names]

  colnames(df)[1] <- IMMCOL$count
  colnames(df)[2] <- IMMCOL$prop
  colnames(df)[3] <- IMMCOL$cdr3nt
  colnames(df)[4] <- IMMCOL$cdr3aa
  colnames(df)[5] <- IMMCOL$v
  colnames(df)[6] <- IMMCOL$d
  colnames(df)[7] <- IMMCOL$j
  colnames(df)[8] <- IMMCOL$ve
  colnames(df)[9] <- IMMCOL$ds
  colnames(df)[10] <- IMMCOL$de
  colnames(df)[11] <- IMMCOL$js
  colnames(df)[12] <- IMMCOL$vnj
  colnames(df)[13] <- IMMCOL$vnd
  colnames(df)[14] <- IMMCOL$dnj

  .postprocess(df, .mode)
}

parse_immunoseq <- function(.filename, .mode, .wash.alleles = TRUE) {
  .fix.immunoseq.genes <- function(.col) {
    # fix ","
    .col <- gsub(",", ", ", .col, fixed = TRUE, useBytes = TRUE)
    # fix forward zeros
    .col <- gsub("-([0])([0-9])", "-\\2", .col, useBytes = TRUE)
    .col <- gsub("([VDJ])([0])([0-9])", "\\1\\3", .col, useBytes = TRUE)
    # fix gene names
    .col <- gsub("TCR", "TR", .col, fixed = TRUE, useBytes = TRUE)
    .col
  }

  filename <- .filename
  file_cols <- list()
  file_cols[[IMMCOL$count]] <- "templates"
  file_cols[[IMMCOL$cdr3nt]] <- "rearrangement"
  file_cols[[IMMCOL$cdr3aa]] <- "amino_acid"
  file_cols[[IMMCOL$v]] <- "v_resolved"
  file_cols[[IMMCOL$d]] <- "d_resolved"
  file_cols[[IMMCOL$j]] <- "j_resolved"
  file_cols[[IMMCOL$vnj]] <- "n1_insertions"
  file_cols[[IMMCOL$vnd]] <- "n1_insertions"
  file_cols[[IMMCOL$dnj]] <- "n2_insertions"

  v_index_col_name <- "v_index"
  d_index_col_name <- "d_index"
  j_index_col_name <- "j_index"
  n1_index_col_name <- "n1_index"
  n2_index_col_name <- "n2_index"

  #
  # Check for the version of ImmunoSEQ files
  #
  f <- file(.filename, "r")
  l <- readLines(f, 2)
  close(f)
  if (str_detect(l[[1]], "v_gene") && !str_detect(l[[1]], "v_resolved")) {
    file_cols[[IMMCOL$v]] <- "v_gene"
    file_cols[[IMMCOL$d]] <- "d_gene"
    file_cols[[IMMCOL$j]] <- "j_gene"
  } else if (str_detect(l[[1]], "MaxResolved")) {
    file_cols[[IMMCOL$v]] <- "vMaxResolved"
    file_cols[[IMMCOL$d]] <- "dMaxResolved"
    file_cols[[IMMCOL$j]] <- "jMaxResolved"

    file_cols[[IMMCOL$vnj]] <- "n1insertion"
    file_cols[[IMMCOL$vnd]] <- "n1insertion"
    file_cols[[IMMCOL$dnj]] <- "n2insertion"
  }


  l_split <- strsplit(l, "\t")
  if (str_detect(l[[1]], "templates")) {
    if (str_detect(l[[1]], "templates/reads")) {
      file_cols[[IMMCOL$count]] <- "count (templates/reads)"
      file_cols[[IMMCOL$cdr3nt]] <- "nucleotide"
      file_cols[[IMMCOL$cdr3aa]] <- "aminoAcid"
    } else if (l_split[[2]][match("templates", l_split[[1]])] == "null") {
      file_cols[[IMMCOL$count]] <- "reads"
    }
  }

  if (!str_detect(l[[1]], "v_index")) {
    v_index_col_name <- "vindex"
    d_index_col_name <- "dindex"
    j_index_col_name <- "jindex"
    n1_index_col_name <- "n1index"
    n2_index_col_name <- "n2index"
  }

  for (col_name in names(file_cols)) {
    file_cols[[col_name]] <- .make_names(file_cols[[col_name]])
  }

  file_cols[[IMMCOL$prop]] <- IMMCOL$prop
  file_cols[[IMMCOL$ve]] <- IMMCOL$ve
  file_cols[[IMMCOL$ds]] <- IMMCOL$ds
  file_cols[[IMMCOL$de]] <- IMMCOL$de
  file_cols[[IMMCOL$js]] <- IMMCOL$js
  file_cols[[IMMCOL$seq]] <- IMMCOL$seq

  # IO_REFACTOR
  suppressMessages(df <- readr::read_delim(.filename,
                                           col_names = TRUE, col_types = cols(),
                                           delim = "\t", quote = "",
                                           escape_double = FALSE, comment = "",
                                           trim_ws = TRUE, skip = 0
  ))
  # suppressMessages(df <- fread(.filename, data.table = FALSE))

  names(df) <- tolower(names(df))

  df[[file_cols[[IMMCOL$prop]]]] <- df[[file_cols[[IMMCOL$count]]]] / sum(df[[file_cols[[IMMCOL$count]]]])

  # Save full nuc sequences and cut them down to CDR3
  df[[IMMCOL$seq]] <- df[[file_cols[[IMMCOL$cdr3nt]]]]

  # TODO: what if df[["v_index]] has "-1" or something like that?
  df[[file_cols[[IMMCOL$cdr3nt]]]] <- stringr::str_sub(df[[IMMCOL$seq]], df[[v_index_col_name]] + 1, nchar(df[[IMMCOL$seq]]))

  df[[file_cols[[IMMCOL$v]]]] <- .fix.immunoseq.genes(df[[file_cols[[IMMCOL$v]]]])
  df[[file_cols[[IMMCOL$d]]]] <- .fix.immunoseq.genes(df[[file_cols[[IMMCOL$d]]]])
  df[[file_cols[[IMMCOL$j]]]] <- .fix.immunoseq.genes(df[[file_cols[[IMMCOL$j]]]])

  recomb_type <- "VDJ"
  if (recomb_type == "VDJ") {
    df[[file_cols[[IMMCOL$ve]]]] <- df[[n1_index_col_name]] - df[[v_index_col_name]]
    df[[file_cols[[IMMCOL$ds]]]] <- df[[d_index_col_name]] - df[[v_index_col_name]]
    df[[file_cols[[IMMCOL$de]]]] <- df[[n2_index_col_name]] - df[[v_index_col_name]]
    df[[file_cols[[IMMCOL$js]]]] <- df[[j_index_col_name]] - df[[v_index_col_name]]
    file_cols[[IMMCOL$vnj]] <- IMMCOL$vnj
    df[[IMMCOL$vnj]] <- -1
  }

  sample_name_vec <- NA
  if ("sample_name" %in% colnames(df)) {
    if (length(unique(df[["sample_name"]])) > 1) {
      sample_name_vec <- df[["sample_name"]]
    }
  }

  df <- df[unlist(file_cols[IMMCOL$order])]
  names(df) <- IMMCOL$order

  if (.wash.alleles) {
    df <- .remove.alleles(df)
    df[[IMMCOL$v]] <- gsub("([VDJ][0-9]*)$", "\\1-1", df[[IMMCOL$v]], useBytes = TRUE)
    df[[IMMCOL$j]] <- gsub("([VDJ][0-9]*)$", "\\1-1", df[[IMMCOL$j]], useBytes = TRUE)
  }

  if (nrow(df) > 0) {
    if (has_class(df[[IMMCOL$vnj]], "character")) {
      df[[IMMCOL$vnj]][df[[IMMCOL$vnj]] == "no data"] <- NA
    }
    if (has_class(df[[IMMCOL$vnd]], "character")) {
      df[[IMMCOL$vnd]][df[[IMMCOL$vnd]] == "no data"] <- NA
    }
    if (has_class(df[[IMMCOL$dnj]], "character")) {
      df[[IMMCOL$dnj]][df[[IMMCOL$dnj]] == "no data"] <- NA
    }

    df[[IMMCOL$vnj]] <- as.integer(df[[IMMCOL$vnj]])
    df[[IMMCOL$vnd]] <- as.integer(df[[IMMCOL$vnd]])
    df[[IMMCOL$dnj]] <- as.integer(df[[IMMCOL$dnj]])
  }

  df[[IMMCOL$v]][df[[IMMCOL$v]] == "unresolved"] <- NA
  df[[IMMCOL$d]][df[[IMMCOL$d]] == "unresolved"] <- NA
  df[[IMMCOL$j]][df[[IMMCOL$j]] == "unresolved"] <- NA

  if (!is.na(sample_name_vec[1])) {
    df <- lapply(split(df, sample_name_vec), .postprocess)
  } else {
    .postprocess(df)
  }
}

parse_mitcr <- function(.filename, .mode) {
  .skip <- 0
  f <- file(.filename, "r")
  l <- readLines(f, 1)
  # Check for different levels of the MiTCR output
  if (any(stringr::str_detect(l, c("MiTCRFullExport", "mitcr")))) {
    .skip <- 1
  }
  mitcr_format <- 1
  if (stringr::str_detect(l, "MiTCRFullExport") || .skip == 0) {
    mitcr_format <- 2
  }
  close(f)

  if (mitcr_format == 1) {
    filename <- .filename
    .count <- "count"
    nuc.seq <- "cdr3nt"
    aa.seq <- "cdr3aa"
    vgenes <- "v"
    jgenes <- "j"
    dgenes <- "d"
    vend <- "VEnd"
    jstart <- "JStart"
    dstart <- "DStart"
    dend <- "DEnd"
    vd.insertions <- NA
    dj.insertions <- NA
    total.insertions <- NA
    .sep <- "\t"
  } else {
    # Check if there are barcodes
    f <- file(.filename, "r")
    l <- readLines(f, 1 + .skip)[.skip + 1]
    barcodes <- NA
    .count <- "Read count"
    if ("NNNs" %in% strsplit(l, "\t", TRUE)[[1]]) {
      .count <- "NNNs"
    }
    close(f)

    filename <- .filename
    nuc.seq <- "CDR3 nucleotide sequence"
    aa.seq <- "CDR3 amino acid sequence"
    vgenes <- "V segments"
    jgenes <- "J segments"
    dgenes <- "D segments"
    vend <- "Last V nucleotide position"
    jstart <- "First J nucleotide position"
    dstart <- "First D nucleotide position"
    dend <- "Last D nucleotide position"
    vd.insertions <- "VD insertions"
    dj.insertions <- "DJ insertions"
    total.insertions <- "Total insertions"
    .sep <- "\t"
  }

  parse_repertoire(
    .filename = filename, .mode = .mode, .nuc.seq = nuc.seq, .aa.seq = aa.seq, .count = .count, .vgenes = vgenes, .jgenes = jgenes, .dgenes = dgenes,
    .vend = vend, .jstart = jstart, .dstart = dstart, .dend = dend,
    .vd.insertions = vd.insertions, .dj.insertions = dj.insertions,
    .total.insertions = total.insertions, .skip = .skip, .sep = .sep
  )
}

parse_mixcr <- function(.filename, .mode) {
  fix.alleles <- function(.data) {
    .data[[IMMCOL$v]] <- gsub("[*][[:digit:]]*", "", .data[[IMMCOL$v]])
    .data[[IMMCOL$d]] <- gsub("[*][[:digit:]]*", "", .data[[IMMCOL$d]])
    .data[[IMMCOL$j]] <- gsub("[*][[:digit:]]*", "", .data[[IMMCOL$j]])
    .data
  }

  .filename <- .filename
  .count <- "clonecount"
  .sep <- "\t"
  .vend <- "allvalignments"
  .jstart <- "alljalignments"
  .dalignments <- "alldalignments"
  .vd.insertions <- "VD.insertions"
  .dj.insertions <- "DJ.insertions"
  .total.insertions <- "Total.insertions"

  table.colnames <- tolower(make.names(read.table(.filename, sep = .sep, skip = 0, nrows = 1, stringsAsFactors = FALSE, strip.white = TRUE, comment.char = "", quote = "")[1, ]))
  table.colnames <- gsub(".", "", table.colnames, fixed = TRUE)

  # Columns of different MiXCR formats
  # Clone count - Clonal sequence(s) - N. Seq. CDR3
  # cloneCount - clonalSequence - nSeqCDR3
  # cloneCount - targetSequences - nSeqImputedCDR3
  # cloneCount - targetSequences - nSeqCDR3
  if ("targetsequences" %in% table.colnames) {
    if ("nseqimputedcdr3" %in% table.colnames) {
      .nuc.seq <- "nseqimputedcdr3"
    } else {
      .nuc.seq <- "nseqcdr3"
    }

    .big.seq <- "targetsequences"
  } else {
    .nuc.seq <- "nseqcdr3"

    if ("clonalsequences" %in% table.colnames) {
      .big.seq <- "clonalsequences"
    } else if ("clonalsequence" %in% table.colnames) {
      .big.seq <- "clonalsequence"
    } else {
      .big.seq <- NA
    }
  }

  if (!("allvalignments" %in% table.colnames)) {
    if ("allvalignment" %in% table.colnames) {
      .vend <- "allvalignment"
    } else {
      .vend <- NA
    }
  }
  if (!("alldalignments" %in% table.colnames)) {
    if ("alldalignment" %in% table.colnames) {
      .dalignments <- "alldalignment"
    } else {
      .dalignments <- NA
    }
  }
  if (!("alljalignments" %in% table.colnames)) {
    if ("alljalignment" %in% table.colnames) {
      .jstart <- "alljalignment"
    } else {
      .jstart <- NA
    }
  }

  if ("bestvhit" %in% table.colnames) {
    .vgenes <- "bestvhit"
  } else if ("allvhits" %in% table.colnames) {
    .vgenes <- "allvhits"
  } else if ("vhits" %in% table.colnames) {
    .vgenes <- "vhits"
  } else if ("allvhitswithscore" %in% table.colnames) {
    .vgenes <- "allvhitswithscore"
  } else if ("bestvgene" %in% table.colnames) {
    .vgenes <- "bestvgene"
  } else {
    message("Error: can't find a column with V genes")
  }

  if ("bestjhit" %in% table.colnames) {
    .jgenes <- "bestjhit"
  } else if ("alljhits" %in% table.colnames) {
    .jgenes <- "alljhits"
  } else if ("jhits" %in% table.colnames) {
    .jgenes <- "jhits"
  } else if ("alljhitswithscore" %in% table.colnames) {
    .jgenes <- "alljhitswithscore"
  } else if ("bestjgene" %in% table.colnames) {
    .jgenes <- "bestjgene"
  } else {
    message("Error: can't find a column with J genes")
  }

  if ("bestdhit" %in% table.colnames) {
    .dgenes <- "bestdhit"
  } else if ("alldhits" %in% table.colnames) {
    .dgenes <- "alldhits"
  } else if ("dhits" %in% table.colnames) {
    .dgenes <- "dhits"
  } else if ("alldhitswithscore" %in% table.colnames) {
    .dgenes <- "alldhitswithscore"
  } else if ("bestdgene" %in% table.colnames) {
    .dgenes <- "bestdgene"
  } else {
    message("Error: can't find a column with D genes")
  }


  # IO_REFACTOR
  df <- read_delim(
    file = .filename, col_types = cols(),
    delim = .sep, skip = 0, comment = "",
    quote = "", escape_double = FALSE, trim_ws = TRUE
  )
  # df <- fread(.filename, data.table = FALSE)

  #
  # return NULL if there is no clonotypes in the data frame
  #
  if (nrow(df) == 0) {
    return(NULL)
  }

  names(df) <- make.names(names(df))
  names(df) <- tolower(gsub(".", "", names(df), fixed = TRUE))
  names(df) <- str_replace_all(names(df), " ", "")

  # check for VJ or VDJ recombination
  # VJ / VDJ / Undeterm
  recomb_type <- "Undeterm"
  if (sum(substr(head(df)[[.vgenes]], 1, 4) %in% c("TCRA", "TRAV", "TRGV", "IGKV", "IGLV"))) {
    recomb_type <- "VJ"
  } else if (sum(substr(head(df)[[.vgenes]], 1, 4) %in% c("TCRB", "TRBV", "TRDV", "IGHV"))) {
    recomb_type <- "VDJ"
  }

  if (!is.na(.vend) && !is.na(.jstart)) {
    .vd.insertions <- "VD.insertions"
    df$VD.insertions <- -1
    if (recomb_type == "VJ") {
      df$VD.insertions <- -1
    } else if (recomb_type == "VDJ") {
      logic <- sapply(strsplit(df[[.dalignments]], "|", TRUE, FALSE, TRUE), length) >= 4 &
        sapply(strsplit(df[[.vend]], "|", TRUE, FALSE, TRUE), length) >= 5
      df$VD.insertions[logic] <-
        as.numeric(sapply(strsplit(df[[.dalignments]][logic], "|", TRUE, FALSE, TRUE), "[[", 4)) -
        as.numeric(sapply(strsplit(df[[.vend]][logic], "|", TRUE, FALSE, TRUE), "[[", 5)) - 1
    }

    .dj.insertions <- "DJ.insertions"
    df$DJ.insertions <- -1
    if (recomb_type == "VJ") {
      df$DJ.insertions <- -1
    } else if (recomb_type == "VDJ") {
      logic <- sapply(strsplit(df[[.jstart]], "|", TRUE, FALSE, TRUE), length) >= 4 &
        sapply(strsplit(df[[.dalignments]], "|", TRUE, FALSE, TRUE), length) >= 5
      df$DJ.insertions[logic] <-
        as.numeric(sapply(strsplit(df[[.jstart]][logic], "|", TRUE, FALSE, TRUE), "[[", 4)) -
        as.numeric(sapply(strsplit(df[[.dalignments]][logic], "|", TRUE, FALSE, TRUE), "[[", 5)) - 1
    }

    # VJ.insertions
    logic <- (sapply(strsplit(df[[.vend]], "|", TRUE, FALSE, TRUE), length) > 4) & (sapply(strsplit(df[[.jstart]], "|", TRUE, FALSE, TRUE), length) >= 4)
    .total.insertions <- "Total.insertions"
    if (recomb_type == "VJ") {
      df$Total.insertions <- NA
      if (length(which(logic)) > 0) {
        df$Total.insertions[logic] <-
          as.numeric(sapply(strsplit(df[[.jstart]][logic], "|", TRUE, FALSE, TRUE), "[[", 4)) - as.numeric(sapply(strsplit(df[[.vend]][logic], "|", TRUE, FALSE, TRUE), "[[", 5)) - 1
      }
    } else if (recomb_type == "VDJ") {
      df$Total.insertions <- df[[.vd.insertions]] + df[[.dj.insertions]]
    } else {
      df$Total.insertions <- NA
    }
    df$Total.insertions[df$Total.insertions < 0] <- -1

    df$V.end <- -1
    df$J.start <- -1
    df[[.vend]] <- gsub(";", "", df[[.vend]], fixed = TRUE)
    logic <- sapply(strsplit(df[[.vend]], "|", TRUE, FALSE, TRUE), length) >= 5
    df$V.end[logic] <- sapply(strsplit(df[[.vend]][logic], "|", TRUE, FALSE, TRUE), "[[", 5)
    logic <- sapply(strsplit(df[[.jstart]], "|", TRUE, FALSE, TRUE), length) >= 4
    df$J.start[logic] <- sapply(strsplit(df[[.jstart]][logic], "|", TRUE, FALSE, TRUE), "[[", 4)
  } else {
    df$V.end <- -1
    df$J.start <- -1
    df$Total.insertions <- -1
    df$VD.insertions <- -1
    df$DJ.insertions <- -1

    .dj.insertions <- "DJ.insertions"
    .vd.insertions <- "VD.insertions"
  }

  .vend <- "V.end"
  .jstart <- "J.start"

  if (!is.na(.dalignments)) {
    logic <- sapply(str_split(df[[.dalignments]], "|"), length) >= 5
    df$D5.end <- -1
    df$D3.end <- -1
    df$D5.end[logic] <- sapply(str_split(df[[.dalignments]][logic], "|"), "[[", 4)
    df$D3.end[logic] <- sapply(str_split(df[[.dalignments]][logic], "|"), "[[", 5)
    .dalignments <- c("D5.end", "D3.end")
  } else {
    df$D5.end <- -1
    df$D3.end <- -1
  }

  .dalignments <- c("D5.end", "D3.end")

  if (!(.count %in% table.colnames)) {
    warn_msg <- c("  [!] Warning: can't find a column with clonal counts. Setting all clonal counts to 1.")
    warn_msg <- c(warn_msg, "\n      Did you apply repLoad to MiXCR file *_alignments.txt?")
    warn_msg <- c(warn_msg, " If so please consider moving all *.clonotypes.*.txt MiXCR files to")
    warn_msg <- c(warn_msg, " a separate folder and apply repLoad to the folder.")
    warn_msg <- c(warn_msg, "\n      Note: The *_alignments.txt file IS NOT a repertoire file suitable for any analysis.")
    message(warn_msg)

    df[[.count]] <- 1
  }
  .freq <- "Proportion"
  df$Proportion <- df[[.count]] / sum(df[[.count]], na.rm = TRUE)

  .aa.seq <- IMMCOL$cdr3aa
  df[[.aa.seq]] <- bunch_translate(df[[.nuc.seq]])

  if (is.na(.big.seq)) {
    .big.seq <- "BigSeq"
    df$BigSeq <- df[[.nuc.seq]]
  }

  df <- df[, make.names(c(
    .count, .freq,
    .nuc.seq, .aa.seq,
    .vgenes, .dgenes, .jgenes,
    .vend, .dalignments, .jstart,
    .total.insertions, .vd.insertions, .dj.insertions, .big.seq
  ))]

  colnames(df) <- IMMCOL$order

  df[[IMMCOL$v]] <- gsub("([*][[:digit:]]*)([(][[:digit:]]*[.,]*[[:digit:]]*[)])", "", df[[IMMCOL$v]])
  df[[IMMCOL$v]] <- gsub(",", ", ", df[[IMMCOL$v]])
  df[[IMMCOL$v]] <- str_replace_all(df[[IMMCOL$v]], '"', "")

  # Remove sorting because MiXCR outputs segments in a specific order
  df[[IMMCOL$v]] <- sapply(
    strsplit(df[[IMMCOL$v]], ", ", useBytes = TRUE),
    # function(x) paste0(sort(unique(x)), collapse = ", ")
    function(x) paste0(unique(x), collapse = ", ")
  )

  df[[IMMCOL$d]] <- gsub("([*][[:digit:]]*)([(][[:digit:]]*[.,]*[[:digit:]]*[)])", "", df[[IMMCOL$d]])
  df[[IMMCOL$d]] <- gsub(",", ", ", df[[IMMCOL$d]])
  df[[IMMCOL$d]] <- str_replace_all(df[[IMMCOL$d]], '"', "")
  df[[IMMCOL$d]] <- sapply(
    strsplit(df[[IMMCOL$d]], ", ", useBytes = TRUE),
    # function(x) paste0(sort(unique(x)), collapse = ", ")
    function(x) paste0(unique(x), collapse = ", ")
  )

  df[[IMMCOL$j]] <- gsub("([*][[:digit:]]*)([(][[:digit:]]*[.,]*[[:digit:]]*[)])", "", df[[IMMCOL$j]])
  df[[IMMCOL$j]] <- gsub(",", ", ", df[[IMMCOL$j]])
  df[[IMMCOL$j]] <- str_replace_all(df[[IMMCOL$j]], '"', "")
  df[[IMMCOL$j]] <- sapply(
    strsplit(df[[IMMCOL$j]], ", ", useBytes = TRUE),
    # function(x) paste0(sort(unique(x)), collapse = ", ")
    function(x) paste0(unique(x), collapse = ", ")
  )

  .postprocess(fix.alleles(df))
}

parse_migec <- function(.filename, .mode) {
  filename <- .filename
  nuc.seq <- "CDR3 nucleotide sequence"
  aa.seq <- "CDR3 amino acid sequence"
  .count <- "Good events"
  vgenes <- "V segments"
  jgenes <- "J segments"
  dgenes <- "D segments"
  vend <- "Last V nucleotide position"
  jstart <- "First J nucleotide position"
  dstart <- "First D nucleotide position"
  dend <- "Last D nucleotide position"
  vd.insertions <- "VD insertions"
  dj.insertions <- "DJ insertions"
  total.insertions <- "Total insertions"
  .skip <- 0
  .sep <- "\t"

  parse_repertoire(
    .filename = filename, .mode = .mode, .nuc.seq = nuc.seq, .aa.seq = aa.seq, .count = .count,
    .vgenes = vgenes, .jgenes = jgenes, .dgenes = dgenes,
    .vend = vend, .jstart = jstart, .dstart = dstart, .dend = dend,
    .vd.insertions = vd.insertions, .dj.insertions = dj.insertions,
    .total.insertions = total.insertions, .skip = .skip, .sep = .sep
  )
}

parse_migmap <- function(.filename, .mode) {
  filename <- .filename
  nuc.seq <- "cdr3nt"
  aa.seq <- "cdr3aa"
  .count <- "count"
  vgenes <- "v"
  jgenes <- "j"
  dgenes <- "d"
  vend <- "v.end.in.cdr3"
  jstart <- "j.start.in.cdr3"
  dstart <- "d.start.in.cdr3"
  dend <- "d.end.in.cdr3"
  vd.insertions <- NA
  dj.insertions <- NA
  total.insertions <- NA
  .skip <- 0
  .sep <- "\t"

  parse_repertoire(
    .filename = filename, .mode = .mode, .nuc.seq = nuc.seq, .aa.seq = aa.seq, .count = .count, .vgenes = vgenes, .jgenes = jgenes, .dgenes = dgenes,
    .vend = vend, .jstart = jstart, .dstart = dstart, .dend = dend,
    .vd.insertions = vd.insertions, .dj.insertions = dj.insertions,
    .total.insertions = total.insertions, .skip = .skip, .sep = .sep
  )
}

parse_tcr <- function(.filename, .mode) {
  f <- file(.filename, "r")
  l <- readLines(f, 2)[2]
  close(f)

  nuc.seq <- "CDR3.nucleotide.sequence"
  aa.seq <- "CDR3.amino.acid.sequence"
  .count <- "Read.count"
  vgenes <- "V.gene"
  jgenes <- "J.gene"
  dgenes <- "D.gene"
  vend <- "V.end"
  jstart <- "J.start"
  dstart <- "D5.end"
  dend <- "D3.end"
  vd.insertions <- "VD.insertions"
  dj.insertions <- "DJ.insertions"
  total.insertions <- "Total.insertions"
  .skip <- 0
  .sep <- "\t"

  if (substr(l, 1, 2) != "NA") {
    .count <- "Umi.count"
  }

  parse_repertoire(
    .filename = .filename, .mode = .mode, .nuc.seq = nuc.seq, .aa.seq = aa.seq, .count = .count, .vgenes = vgenes, .jgenes = jgenes, .dgenes = dgenes,
    .vend = vend, .jstart = jstart, .dstart = dstart, .dend = dend,
    .vd.insertions = vd.insertions, .dj.insertions = dj.insertions,
    .total.insertions = total.insertions, .skip = .skip, .sep = .sep
  )
}

parse_vdjtools <- function(.filename, .mode) {
  skip <- 0

  # Check for different VDJtools outputs
  f <- file(.filename, "r")
  l <- readLines(f, 1)
  close(f)

  .skip <- 0
  .count <- "count"
  filename <- .filename
  nuc.seq <- "cdr3nt"
  aa.seq <- "CDR3aa"
  vgenes <- "V"
  jgenes <- "J"
  dgenes <- "D"
  vend <- "Vend"
  jstart <- "Jstart"
  dstart <- "Dstart"
  dend <- "Dend"
  vd.insertions <- NA
  dj.insertions <- NA
  total.insertions <- NA
  .sep <- "\t"

  if (length(strsplit(l, "-", TRUE)) > 0) {
    if (length(strsplit(l, "-", TRUE)[[1]]) == 3) {
      if (strsplit(l, "-", TRUE)[[1]][2] == "header") {
        .count <- "count"
        .skip <- 1
      }
    } else if (tolower(substr(l, 1, 2)) == "#s") {
      .count <- "#Seq. count"
      nuc.seq <- "N Sequence"
      aa.seq <- "AA Sequence"
      vgenes <- "V segments"
      jgenes <- "J segments"
      dgenes <- "D segment"
      vend <- NA
      jstart <- NA
      dstart <- NA
      dend <- NA
    } else if (stringr::str_detect(l, "#")) {
      .count <- "X.count"
    } else {
      .count <- "count"
    }
  }

  parse_repertoire(
    .filename = filename, .mode = .mode, .nuc.seq = nuc.seq, .aa.seq = aa.seq, .count = .count, .vgenes = vgenes, .jgenes = jgenes, .dgenes = dgenes,
    .vend = vend, .jstart = jstart, .dstart = dstart, .dend = dend,
    .vd.insertions = vd.insertions, .dj.insertions = dj.insertions,
    .total.insertions = total.insertions, .skip = .skip, .sep = .sep
  )
}

parse_imgt <- function(.filename, .mode) {
  .fix.imgt.alleles <- function(.col) {
    sapply(strsplit(.col, " "), function(x) {
      if (length(x) > 1) {
        x[[2]]
      } else {
        NA
      }
    })
  }

  f <- file(.filename, "r")
  l <- readLines(f, 2)[2]
  close(f)

  nuc.seq <- "JUNCTION"
  aa.seq <- NA
  .count <- NA
  vgenes <- "V-GENE and allele"
  jgenes <- "J-GENE and allele"
  dgenes <- "D-GENE and allele"
  vend <- "3'V-REGION end"
  jstart <- "5'J-REGION start"
  dstart <- "D-REGION start"
  dend <- "D-REGION end"
  vd.insertions <- NA
  dj.insertions <- NA
  total.insertions <- NA
  .skip <- 0
  .sep <- "\t"
  junc_start <- .make_names("JUNCTION start")

  df <- parse_repertoire(
    .filename = .filename, .mode = .mode, .nuc.seq = nuc.seq, .aa.seq = aa.seq, .count = .count, .vgenes = vgenes, .jgenes = jgenes, .dgenes = dgenes,
    .vend = vend, .jstart = jstart, .dstart = dstart, .dend = dend,
    .vd.insertions = vd.insertions, .dj.insertions = dj.insertions,
    .total.insertions = total.insertions, .skip = .skip, .sep = .sep, .add = junc_start
  )

  df[[IMMCOL$ve]] <- df[[IMMCOL$ve]] - df[[junc_start]]
  df[[IMMCOL$ds]] <- df[[IMMCOL$ds]] - df[[junc_start]]
  df[[IMMCOL$de]] <- df[[IMMCOL$de]] - df[[junc_start]]
  df[[IMMCOL$js]] <- df[[IMMCOL$js]] - df[[junc_start]]

  df[[IMMCOL$ve]][df[[IMMCOL$ve]] < 0] <- NA
  df[[IMMCOL$ds]][df[[IMMCOL$ds]] < 0] <- NA
  df[[IMMCOL$de]][df[[IMMCOL$de]] < 0] <- NA
  df[[IMMCOL$js]][df[[IMMCOL$js]] < 0] <- NA

  df[[IMMCOL$v]] <- .fix.imgt.alleles(df[[IMMCOL$v]])
  df[[IMMCOL$d]] <- .fix.imgt.alleles(df[[IMMCOL$d]])
  df[[IMMCOL$j]] <- .fix.imgt.alleles(df[[IMMCOL$j]])

  df[[junc_start]] <- NULL

  df
}

# parse_vidjil <- function (.filename) {
#   stop(IMMUNR_ERROR_NOT_IMPL)
# }
#
# parse_rtcr <- function (.filename) {
#   stop(IMMUNR_ERROR_NOT_IMPL)
# }
#
# parse_imseq <- function (.filename) {
#   stop(IMMUNR_ERROR_NOT_IMPL)
# }

parse_airr <- function(.filename, .mode) {
  df <- airr::read_rearrangement(.filename)

  df <- df %>%
    select(
      sequence, v_call, d_call, j_call, junction, junction_aa,
      contains("v_germline_end"), contains("d_germline_start"), contains("d_germline_end"),
      contains("j_germline_start"), contains("np1_length"), contains("np2_length"),
      contains("duplicate_count")
    )

  namekey <- c(
    duplicate_count = IMMCOL$count, junction = IMMCOL$cdr3nt, junction_aa = IMMCOL$cdr3aa,
    v_call = IMMCOL$v, d_call = IMMCOL$d, j_call = IMMCOL$j, v_germline_end = IMMCOL$ve,
    d_germline_start = IMMCOL$ds, d_germline_end = IMMCOL$de, j_germline_start = IMMCOL$js,
    np1_length = "unidins", np2_length = IMMCOL$dnj, sequence = IMMCOL$seq
  )

  names(df) <- namekey[names(df)]

  if (!("unidins" %in% colnames(df))) {
    df["unidins"] <- NA
  }

  recomb_type <- .which_recomb_type(df[[IMMCOL$v]])

  if (!is.na(recomb_type)) {
    if (recomb_type == "VJ") {
      df[IMMCOL$vnj] <- df["unidins"]
      df[IMMCOL$vnd] <- NA
      df[IMMCOL$dnj] <- NA
    } else if (recomb_type == "VDJ") {
      df[IMMCOL$vnj] <- NA
      df[IMMCOL$vnd] <- df["unidins"]
    }
  }

  for (column in IMMCOL$order) {
    if (!(column %in% colnames(df))) {
      df[column] <- NA
    }
  }

  df <- df[IMMCOL$order]
  total <- sum(df$Clones)
  df[IMMCOL$prop] <- df[IMMCOL$count] / total
  df[IMMCOL$seq] <- stringr::str_remove_all(df[[IMMCOL$seq]], "N")
  df <- .postprocess(df)
  df
}

parse_immunarch <- function(.filename, .mode) {
  df <- readr::read_tsv(.filename, col_types = cols(), comment = "#")
  if (ncol(df) == 1) {
    # "," in the files, parse differently then
    df <- readr::read_csv(.filename, col_types = cols(), comment = "#")
  }
  df <- .postprocess(df)
  df
}

parse_10x_consensus <- function(.filename, .mode) {
  df <- parse_repertoire(.filename,
                         .mode = .mode,
                         .nuc.seq = "cdr3_nt", .aa.seq = NA, .count = "umis",
                         .vgenes = "v_gene", .jgenes = "j_gene", .dgenes = "d_gene",
                         .vend = NA, .jstart = NA, .dstart = NA, .dend = NA,
                         .vd.insertions = NA, .dj.insertions = NA, .total.insertions = NA,
                         .skip = 0, .sep = ",", .add = c("chain", "clonotype_id", "consensus_id")
  )
  setnames(df, "clonotype_id", "ClonotypeID")
  setnames(df, "consensus_id", "ConsensusID")
  df
}

parse_10x_filt_contigs <- function(.filename, .mode) {
  df <- parse_repertoire(.filename,
                         .mode = .mode,
                         .nuc.seq = "cdr3_nt", .aa.seq = NA, .count = "umis",
                         .vgenes = "v_gene", .jgenes = "j_gene", .dgenes = "d_gene",
                         .vend = NA, .jstart = NA, .dstart = NA, .dend = NA,
                         .vd.insertions = NA, .dj.insertions = NA, .total.insertions = NA,
                         .skip = 0, .sep = ",", # .add = c("chain", "raw_clonotype_id", "raw_consensus_id", "barcode", "contig_id")
                         .add = c("chain", "barcode", "raw_clonotype_id", "contig_id")
  )
  # setnames(df, "raw_clonotype_id", "RawClonotypeID")
  # setnames(df, "raw_consensus_id", "RawConsensusID")

  # Process 10xGenomics filtered contigs files - count barcodes, merge consensues ids, clonotype ids and contig ids
  df <- df[order(df$chain),]
  setDT(df)

  if (.mode == "paired") {
    df <- df %>%
      lazy_dt() %>%
      group_by(barcode, raw_clonotype_id) %>%
      summarise(
        CDR3.nt = paste0(CDR3.nt, collapse = IMMCOL_ADD$scsep),
        CDR3.aa = paste0(CDR3.aa, collapse = IMMCOL_ADD$scsep),
        V.name = paste0(V.name, collapse = IMMCOL_ADD$scsep),
        J.name = paste0(J.name, collapse = IMMCOL_ADD$scsep),
        D.name = paste0(D.name, collapse = IMMCOL_ADD$scsep),
        chain = paste0(chain, collapse = IMMCOL_ADD$scsep),
        # raw_clonotype_id = gsub("clonotype", "", paste0(raw_clonotype_id, collapse = IMMCOL_ADD$scsep)),
        # raw_consensus_id = gsub("clonotype|consensus", "", paste0(raw_consensus_id, collapse = IMMCOL_ADD$scsep)),
        contig_id = gsub("_contig_", "", paste0(contig_id, collapse = IMMCOL_ADD$scsep))
      ) %>%
      as.data.table()
  }
  df <- df %>%
    lazy_dt() %>%
    group_by(CDR3.nt, V.name, J.name) %>%
    summarise(
      Clones = length(unique(barcode)),
      CDR3.aa = first(CDR3.aa),
      D.name = first(D.name),
      chain = first(chain),
      barcode = paste0(unique(barcode), collapse = IMMCOL_ADD$scsep),
      raw_clonotype_id = gsub("clonotype|None", "", paste0(unique(raw_clonotype_id), collapse = IMMCOL_ADD$scsep)),
      # raw_clonotype_id = gsub("clonotype", "", paste0(raw_clonotype_id, collapse = IMMCOL_ADD$scsep)),
      # raw_consensus_id = gsub("clonotype|consensus", "", paste0(raw_consensus_id, collapse = IMMCOL_ADD$scsep)),
      contig_id = paste0(contig_id, collapse = IMMCOL_ADD$scsep)
    ) %>%
    as.data.table()

  df$V.end <- NA
  df$J.start <- NA
  df$D.end <- NA
  df$D.start <- NA
  df$VD.ins <- NA
  df$DJ.ins <- NA
  df$VJ.ins <- NA
  df$Sequence <- df$CDR3.nt

  setnames(df, "contig_id", "ContigID")
  setnames(df, "barcode", "Barcode")

  df[[IMMCOL$prop]] <- df[[IMMCOL$count]] / sum(df[[IMMCOL$count]])
  setcolorder(df, IMMCOL$order)

  setDF(df)

  .postprocess(df)
}

parse_archer <- function(.filename, .mode) {
  parse_repertoire(.filename,
                   .mode = .mode,
                   .nuc.seq = "Clonotype Sequence", .aa.seq = NA, .count = "Clone Abundance",
                   .vgenes = "Predicted V Region", .jgenes = "Predicted J Region", .dgenes = "Predicted D Region",
                   .vend = NA, .jstart = NA, .dstart = NA, .dend = NA,
                   .vd.insertions = NA, .dj.insertions = NA, .total.insertions = NA,
                   .skip = 0, .sep = "\t"
  )
}

parse_catt <- function(.filename, .mode) {
  filename <- .filename
  nuc.seq <- "NNseq"
  aa.seq <- "AAseq"
  .count <- "Frequency"
  vgenes <- "Vregion"
  jgenes <- "Jregion"
  dgenes <- "Dregion"
  vend <- NA
  jstart <- NA
  dstart <- NA
  dend <- NA
  vd.insertions <- "VD insertions"
  dj.insertions <- "DJ insertions"
  total.insertions <- "Total insertions"
  .skip <- 0
  .sep <- ","

  parse_repertoire(
    .filename = filename, .mode = .mode, .nuc.seq = nuc.seq, .aa.seq = aa.seq, .count = .count,
    .vgenes = vgenes, .jgenes = jgenes, .dgenes = dgenes,
    .vend = vend, .jstart = jstart, .dstart = dstart, .dend = dend,
    .vd.insertions = vd.insertions, .dj.insertions = dj.insertions,
    .total.insertions = total.insertions, .skip = .skip, .sep = .sep
  )
}
