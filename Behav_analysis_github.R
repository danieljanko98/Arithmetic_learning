#######################################################################
#           Arithmetic Learning behavioral data processing            #
#######################################################################

# This script takes raw data as input and carries out statistical analysis. The data is assumed to come in a long format with all subjects included in one file. 
# The processing includes cleaning (removal of errors), Bayesian linear modeling of RT, and frequentist mdoeling of errors


# Author: Daniel Janko (daniel.janko@ovgu.de)

packages <- c("brms", "bayesplot", "hypr", "rstan", "ggplot2", "tidyr", "dplyr", "lme4", "readxl")

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
#                      Statistical Analysis                           #
#######################################################################

# Load all the data
data <- read.csv('data_bayes.csv')
data_all <- read.csv('fMRI_session_behavioral.csv')

data$session <- as.factor(data$session)
data$operation <- as.factor(data$operation)
data$carry <- as.factor(data$carry)

# Setting up a sliding differences contrast to examine non-linear effects across the training
contrastSetting(data)

# defining priors - we are expecting a training effect, hence the negative values (decrease in RT)
# We are also expecting the usual non-linear trajectory of the training effect with a steep decrease at the beginning and flattening toward the end - 
# this assumption is reflected in the priors
priors_main <- c(prior(normal(-0.8,0.5), class = b, coef = session2M1),
                 prior(normal(0,1), class = sd, coef = session2M1, group = subject),
                 prior(normal(0,1), class = b, coef = operationP),
                 prior(normal(0,1), class = b, coef = session2M1:operationP),
                 prior(normal(-0.8,0.5), class = b, coef = session3M2),
                 prior(normal(0,1), class = sd, coef = session3M2, group = subject),
                 prior(normal(0,1), class = b, coef = session3M2:operationP),
                 prior(normal(-0.8,0.5), class = b, coef = session4M3),
                 prior(normal(0,1), class = sd, coef = session4M3, group = subject),
                 prior(normal(0,1), class = b, coef = session4M3:operationP),
                 prior(normal(0, 2), class = sigma)
)

# Fitting the model 
model_main <- brm(log(RT) ~ 1 + session * operation + (session || subject), 
                  data = data,
                  iter = 20000,
                  control = list(adapt_delta = 0.99, max_treedepth = 12),
                  threads = threading(4),
                  cores = 4,
                  save_pars = save_pars(all = TRUE),
                  backend = "cmdstanr", 
                  prior = priors_main)

# Saving the model
summary(model_main)
save(model_main, file = "Bayes_model_main_new.RData")
load("Bayes_model_main_new.RData")


# Shuffling the data and running the same model again
set.seed(2025)

shuf_data <- data
shuf_data$RT <- sample(shuf_data$RT)

model_shuf <- brm(log(RT) ~ 1 + session * operation + (session || subject), 
                  data = shuf_data,
                  iter = 20000,
                  control = list(adapt_delta = 0.99, max_treedepth = 12),
                  threads = threading(4),
                  cores = 4,
                  save_pars = save_pars(all = TRUE),
                  backend = "cmdstanr", 
                  prior = priors_main)

summary(model_shuf)
save(model_shuf, file = "Bayes_model_shuf.RData")
# Error analysis 

priors_ACC <- c(prior(normal(0,1), class = b, coef = session2M1),
                prior(normal(0,1), class = b, coef = operationP),
                prior(normal(0,1), class = sd, coef = session2M1, group = subject),
                prior(normal(0,1), class = b, coef = session2M1:operationP),
                prior(normal(0,1), class = b, coef = session3M2),
                prior(normal(0,1), class = sd, coef = session3M2, group = subject),
                prior(normal(0,1), class = b, coef = session3M2:operationP),
                prior(normal(0,1), class = b, coef = session4M3),
                prior(normal(0,1), class = sd, coef = session4M3, group = subject),
                prior(normal(0,1), class = b, coef = session4M3:operationP)
)

model_acc <- brm(correct ~ 1 + session * operation + (session || subject),
                 data = data,
                 prior = priors_ACC,
                 family = bernoulli(link = logit),
                 iter = 20000,
                 control = list(adapt_delta = 0.99, max_treedepth = 12),
                 threads = threading(4),
                 cores = 4,
                 save_pars = save_pars(all = TRUE),
                 backend = "cmdstanr")

summary(model_acc)
save(model_acc, file = "Bayes_model_acc_new.RData")

####################################################
## Analysis of behavioral data from fMRI sessions ##
####################################################
prior <- c(prior(normal(0,1), class = b, coef = oper),
             prior(normal(0,1), class = b, coef = trained),
             prior(normal(0,1), class = b, coef = trained:oper),
             prior(normal(0,1), class = sd, coef = trained, group = subj))

model <- brm(log(RT) ~ trained * oper + (trained || subj), data = data_all, prior = prior,
             iter = 20000,
             threads = threading(4),
             cores = 4,
             save_pars = save_pars(all = TRUE),
             backend = "cmdstanr")
summary(model)