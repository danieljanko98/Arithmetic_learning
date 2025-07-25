packages <- c("ggplot2", "tidyr", "dplyr", 'bayesplot', 'patchwork')

# Function to check if packages are installed, install them if not, and load them
load_packages <- function(packages) {
  for (package in packages) {
    if (!require(package, character.only = TRUE)) {
      install.packages(package)
      if (!require(package, character.only = TRUE)) {
        stop(paste("Package", package, "not found and installation failed. Please install it manually."))
      }
    }
    library(package, character.only = TRUE)
  }
}
load_packages(packages)
source('.../functions_github.R')
setwd('.../data/')

#######################################################################
#                           Plotting RT Model                         #
#######################################################################

load('Bayes_model_main_new.RData')
# Examining the model (probability = probability of each estimated fixed effect being different from 0)
modelExploration(model_main)

# Estimated ßs (thin line represents 95% confidence interval and thick line represents 80%)
print(model_figure)
Fig2A <- model_figure
# probbaility of the estimates being different from 0 (Intercept, ß1, ß2, ß3)
print(probability)

data <- read.csv('/Users/danieljanko/Desktop/Projects/Arithmetic_learning/behav_data/data/clean_data.csv')

mainPlot(data)

Fig2B <- main_plot

Fig2A + Fig2B + plot_layout(ncol = 2) +
  theme(plot.background = element_rect(color = "black", fill = NA, size = 1),
        plot.margin = margin(10, 10, 10, 10))  # Add margin inside each plot
#######################################################################
#                           Plotting Error Model                      #
#######################################################################

data_error <- read.csv('error_rate.csv')
colnames(data_error) <- c("Subject", "Ses1", "Ses2", "Ses3", "Ses4")
data_error <- data_error[ -1,]

errorPlot(data_error)
print(error_plot)