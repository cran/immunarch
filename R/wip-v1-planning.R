# The package ecosystem (principles -> focus on the goal + don't make users install more than they really need):
# - immundata -- foundational data structure
# - immunarch -- basic analysis and exploration
# - immungraph -- Network-based Methods for AIRR Analysis: BCR Lineage and Somatic Hypermutations, Sequence Similarity, Graphs
#   -- distances / graphs / clusters -> `immungraph` that creates receptor_groups on top of ImmunData
# - immunext -- some analysis of repertoires, hclust and other bullshit maybe? Solutions seems like a place for omicseer tho
# - - maybe those complex analyses include dimensionality stuff
# - fixvis - separate package OR https://github.com/smouksassi/ggplotwithyourdata
#
# - https://genomicsinform.biomedcentral.com/articles/10.1186/s44342-024-00034-z/
#
# immunarch_updates() function with the previous updates



# -- Repertoire-level analysis
# airr_basic_stats (airr_explore)
# - lengths
# - receptors
# - sum(counts)
# airr_clonality
# - clonal space homeostasis -> annotate receptors
# airr_public_index (airr_overlap | airr_public | airr_distance | airr_metric | airr_public_index)
# - no. public
# - jaccard
# - * morisita
# airr_genes
# - gene segments statistics
# airr_diversity
# - d50
# - chao1
# - * hill numbers
# airr_rarefaction
# - * rarefaction
# airr_spectratyping
# - * spectratyping
#
# -- Receptor-level analysis
# receptor_track | track_receptors (receptor_search) Search receptors across repertoires and track their counts
# - pass a data frame with one or multiple features from receptors.parquet
# - * find receptors by levenshtein distance
# receptor_query (receptor_search | read_database | receptor_annotate | search_receptors | receptor_query)
# - TODO: Don't you think that this is a function for immundata?
# - * find receptors by levenshtein distance
# receptor_graph
# - * ...
# receptor_public -> get public / shared receptors | public_receptors
# - get public receptors
# - get public receptors by some query - like minimal amount of incidence or differences in counts
# - * get receptors by levenshtein distance
#
# ---
#
# airr_overlap
# exploration-overlaps:
# - public
# - overlap
# - jaccard
# - cosine
# - morisita-horn
#
# airr_genes
# exploration-geneusage:
#   ...
#
# airr_diversity
# exploration-diversity:
#   - Pielou’s index
#
# airr_rarefaction
# exploration-rarefaction:
#   ...
#
# clonality
# exploration-clonality:
#   ...
#
# exploration-spectratyping [?]:
#   ...
#
# track_receptors [among repertoires]
# search_receptors [in database]
# analysis-tracking:
#   ...
#
# chemoproperties
#
#
# Somatic hypermutation rate
#
# Annotation-specific analysis:
#   - specificity
#   - coordinates
#   - trjectory analysis
#   - trajectory analysis + clustering beforehand + receptor specificity
#
#
# clustering / motifs
