#######################################################################
#           Arithmetic Learning behavioral data processing            #
#######################################################################

# This script takes raw data as input and carries out statistical analysis. The data is assumed to come in a long format with all subjects included in one file. 
# The processing includes cleaning (removal of errors), Bayesian linear modeling of RT, and frequentist mdoeling of errors


# Author: Daniel Janko (daniel.janko@ovgu.de)

packages <- c("brms", "bayesplot", "hypr", "rstan", "ggplot2", "tidyr", "dplyr", 'lme4')

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


source('/Users/danieljanko/Desktop/Projects/Arithmetic_learning/behav_data/functions/functions.R')
setwd('/Users/danieljanko/Desktop/Projects/Arithmetic_learning/behav_data/data/')

#######################################################################
#                           Data Cleaning                             #
#######################################################################
# loading data
data <- read.csv('/Users/danieljanko/Desktop/Projects/Arithmetic_learning/behav_data/data/data_prepped.csv')

# setting other variables
subj <- c("sub8", "sub9", "sub10", "sub11", "sub14", "sub15", "sub16", 
          "sub17", "sub18", "sub19", "sub20", "sub21", "sub23", 
          "sub24", "sub25", "sub26", "sub28")
sessions <- c(1, 2, 3, 4)

# calling a function to count and remove errors
errorRemoval(data, subj, sessions)

# exporting the two new df
write.csv(error_rate, "error_rate.csv")
write.csv(data, "data_bayes.csv")

#######################################################################
#                      Statistical Analysis                           #
#######################################################################
data <- read.csv('data_bayes.csv')

data$session <- as.factor(data$session)
data$operation <- as.factor(data$operation)

# Setting up a sliding differences contrast to examine non-linear effects accross the training
contrastSetting(data)


# defining priors - we are expecting a training effect, hence the negative values (decrease in RT)
# We are also expecting the usual non-linear trajectory of the training effect with a steep decrease at the beginning and flattening toward the end - 
# this assumption is reflected in the priors
priors_main <- c(prior(normal(-0.8,0.5), class = b, coef = session2M1),
                 prior(normal(-0.5,0.5), class = b, coef = session3M2),
                 prior(normal(-0.2,0.5), class = b, coef = session4M3),
                 prior(normal(0, 2), class = sigma)
)

# Fitting the model 
model_main <- brm(log(RT) ~ 1 + session + (0 + session||subject), 
           data = data,
           iter = 20000,
           control = list(adapt_delta = 0.99, max_treedepth = 12),
           prior = priors_main)

# Saving the model
summary(model_main)
save(model_main, file = "Bayes_model_main.RData")

# Error analysis - not using bayesian modeling here since it is not main measure of interest

# Loading df and renaming columns
data_error <- read.csv('error_rate.csv')
colnames(data_error) <- c("Subject", "Ses1", "Ses2", "Ses3", "Ses4")
data_error <- data_error[ -18,]

# transforming the df to a long format
data_error <- data_error %>%
  pivot_longer(cols = starts_with("Ses"),
               names_to = "session",
               values_to = "Error")
data_error$session <- as.factor(data_error$session)

contrastSetting(data_error)
# fitting the model
error_model <- lm(Error ~ session, data = data_error)

# examining and savign the model
summary(error_model)
save(error_model, file = "Error_model.RData")







