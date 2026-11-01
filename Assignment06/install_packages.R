# Run once in RStudio. This installs only missing dashboard packages.
packages <- c("shiny", "ggplot2", "quantmod")
missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing, repos = "https://cloud.r-project.org")
for (package in packages) cat(package, as.character(packageVersion(package)), "\n")
