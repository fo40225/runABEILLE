# Load necessary libraries
library(optparse)
library(dplyr)

# Loading ABEILLE library
library("ABEILLE")

# Function to read featureCounts files and create a table
read_and_combine_featureCounts <- function(directory) {
  # Get a list of files in the specified directory
  files <- list.files(directory, full.names = TRUE)

  # Initialize an empty data frame to store combined data
  combined_data <- data.frame()

  for (file in files) {
    # Extract sample name from the filename (remove everything after the first dot)
    sample_name <- gsub("\\..*$", "", basename(file))

    # Read data from the file, skipping comments and header
    data <- read.table(file, header = TRUE, comment.char = "#", sep = "\t", stringsAsFactors = FALSE)

    # Extract the first and last columns
    subset_data <- data %>% select(1, ncol(data))

    # Rename the columns to the sample name
    colnames(subset_data) <- c("Geneid", sample_name)

    # Combine data based on Geneid
    if (nrow(combined_data) == 0) {
      combined_data <- subset_data
    } else {
      combined_data <- left_join(combined_data, subset_data, by = "Geneid")
    }
  }

  return(combined_data)
}

# Function to write combined data to a TSV file
write_combined_data <- function(combined_data, outfile) {
  write.table(combined_data, file = outfile, sep = "\t", quote = FALSE, row.names = TRUE)
}

# Define command-line options
option_list <- list(
  make_option(c("-i", "--inputDir"), type = "character", help = "Path to the input data directory"),
  make_option(c("-o", "--outputFile"), type = "character", help = "Path to the output TSV file")
)

# Parse command-line arguments
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

# Check if required options are provided
if (is.null(opt$inputDir) || is.null(opt$outputFile)) {
  stop("Usage: Rscript runABEILLE.R --inputDir <dir> --outputFile <result.tsv>")
}

# Read and combine featureCounts data
combined_data <- read_and_combine_featureCounts(opt$inputDir)

# Set the first column as row names
row_names <- combined_data[, 1]
combined_data <- combined_data[, -1]
rownames(combined_data) <- row_names

# Quality control of the data. Ensure that the data are conform and can be used within ABEILLE by running the DataIntegrity function.
DataIntegrity(combined_data)

# Remove unexpressed genes in all patients. Filter out unexpressed genes with the RemoveZeroCounts function.
combined_data <- RemoveZeroCounts(combined_data)

# Save the dataset that was created after removing the zero counts.
write.csv(combined_data, "combined_data.csv")

# Load the Python environment for ABEILLE
library(reticulate)

# Load the VAE function from Python script (abeille.py)
source_python("abeille.py")
dataset_recons <- abeille_VAE("combined_data.csv")

# Judge the performance of the reconstruction using the StatsPred function.
StatsPred(combined_data, dataset_recons)

# Compute two novel metrics (divergence score and delta count) with DivergenceScore and DeltaCount functions.
divergence_score <- DivergenceScore(combined_data, dataset_recons)
delta_count <- DeltaCount(combined_data, dataset_recons)

# Identify AGEs using the IdentifyAGE function. It also uses ComputeAnomalyScore to return an anomaly score associated with each AGE between 0 and 1.
ages <- IdentifyAGE(divergence_score, delta_count, combined_data, dataset_recons)

# Write AGE data to the output file
write_combined_data(ages, opt$outputFile)

cat("Results saved to", opt$outputFile, "\n")
