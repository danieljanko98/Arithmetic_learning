# Counting and removing errors
errorRemoval <- function(data, subj, sessions) {
  # Generating error rates for each subject for each session
  error_rate <- data.frame(matrix(nrow = length(subj), ncol = length(sessions)))
  for (s in 1:length(subj)) {
    a <- subset(data, subject == subj[s])
    for (j in 1:length(sessions)) {
      b <- subset(a, session == sessions[j])
      error_rate99 <- which(b$correct == 99)
      error_rate98 <- which(b$correct == 98)
      error_rate0 <- which(b$correct == 0)
      error_rate[s,j] <- length(error_rate99) + length(error_rate0) + length(error_rate98)
    }
  }
  
  # removing errors 
  error_rates <- which(data$correct == 98 | data$correct == 0)
  error_rate99 <- which(data$correct == 99)
  data <- data[-c(error_rates, error_rate99, error_rate99 + 1), ]
  data <- na.omit(data)
  write.csv(data, 'clean_data.csv')
  data <<- data
  error_rate <<- error_rate
  
}

# Setting up contrast
contrastSetting <- function(data) {
  c <- hypr()
  cmat(c, add_intercept = TRUE) <- MASS::contr.sdif(4)
  contrasts(data$session) <- contr.hypothesis(c)
}

# Posterior exploration
modelExploration <- function(model_main) {
  df_model_main <- as.data.frame(model_main)
  var_names_log <- colnames(df_model_main)[2:4]
  log_model_figure <- mcmc_intervals(model_main,
                                     regex_pars = var_names_log,
                                     prob_outer = .95,
                                     prob = .8,
                                     point_size = 2.5,
                                     inner_size = 1,
                                     point_est = "mean")
  print(log_model_figure)
  
  # Getting the probability of observing effect between -0.01 and 0.01 given the posterior distributions
  effects <- fixef(model_main)
  # Probability for Intercept, beta1, beta2, beta3
  probs <- vector()
  for (i in 1:4) {
    probs[i] <- round(pnorm(0.01, mean = effects[i,1], sd = effects[i,2]) - pnorm(-0.01, mean = effects[i,1], sd = effects[i,2]), 3)
  }
  
  model_figure <<- log_model_figure
  probability <<-probs
}

mainPlot <- function(data) {
  summary_df <- data %>%
    group_by(session) %>%
    summarise(
      mean_RT = mean(RT),  
      se_value = sd(RT, na.rm = TRUE) / sqrt(n()))
  
  main_plot <<- ggplot(summary_df, aes(x = factor(session), y = mean_RT)) +
    geom_point(stat = "identity", color = "black") +  # Bar plot
    geom_errorbar(aes(ymin = mean_RT - se_value, ymax = mean_RT + se_value), width = 0.1, color = 'black') +  # Error bars
    labs(x = "Session", y = "Reaction Time (ms)", title = "Mean RT by Session with SE") +
    theme_minimal()
 
}

errorPlot <- function(data_error) {
  # transforming the df to a long format
  data_error <- data_error %>%
    pivot_longer(cols = starts_with("Ses"),
                 names_to = "session",
                 values_to = "error")
  
  df_summary <- data_error %>%
    group_by(session) %>%
    summarise(mean_value = mean(error, na.rm = TRUE),
              se_value = sd(error, na.rm = TRUE) / sqrt(n()))

  
  error_plot <<- ggplot(df_summary, aes(x = as.factor(session), y = mean_value)) +
    geom_point(, color = 'black') +
    geom_errorbar(aes(ymin = mean_value - se_value, ymax = mean_value + se_value), width = 0.1, color = 'black') + 
    labs(title = "Mean Error per Session", x = "Session", y = "Mean Error") +
    theme_minimal() +
    theme(legend.position = "none")
}
