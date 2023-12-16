options(timeout=0, repos = 'https://cloud.r-project.org')
install.packages(c('crayon', 'e1071', 'matrixStats', 'progress', 'reticulate', 'solitude', 'dplyr', 'optparse'), Ncpus=parallel::detectCores())

if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

Sys.setenv(MAKEFLAGS = paste("-j", parallel::detectCores()))
BiocManager::install(c('edgeR', 'DESeq2'))

install.packages('ABEILLE_1.0.0.tar.gz', repos = NULL, type='source', Ncpus=parallel::detectCores())
