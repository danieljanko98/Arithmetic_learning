# Setting up contrast
contrastSetting <- function(data) {
  c <- hypr()
  cmat(c, add_intercept = TRUE) <- MASS::contr.sdif(4)
  contrasts(data$session) <- contr.hypothesis(c)
  data <<- data
}

# Posterior exploration
modelExploration <- function(model_main) {
  df_model_main <- as.data.frame(model_main)
  var_names_log <- colnames(df_model_main)[2:4]
  model_data <- df_model_main[,c(2:4)]
  colnames(model_data) <- c("S1-S2", "S2-S3", "S3-S4")
  model_data <- pivot_longer(model_data, 
                             cols = everything(),
                             names_to = 'beta',
                             values_to = 'values')
  log_model_figure <- ggplot(model_data, aes(x = beta, y = values)) +
    geom_half_violin(side = 'l') +
    geom_hline(yintercept = 0, linetype = 'dashed') +
    ggtitle("A") + 
    theme(plot.background = element_rect(color = "black", fill = NA, size = 1),
          plot.title = element_text(size = 16, face = 'bold', hjust = -0.02))
  
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
  data$session <- as.factor(data$session)
  main_plot <<- ggplot(data, aes(x = session, y = RT)) +
    geom_boxplot(outlier.shape = 21) +
    labs(title = "B",
         x = "Training session",
         y = "Response time") +
    theme(plot.background = element_rect(color = "black", fill = NA, size = 1),
          plot.title = element_text(size = 16, face = 'bold', hjust = -0.02))
  
  
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