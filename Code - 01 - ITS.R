# Jihoon Lim
# ITS Analysis
# August 26, 2026

library(car); library(nlme); library(sandwich); library(lmtest); library(tsModel)
library(dplyr); library(haven); library(ggplot2); library(tibble); library(forecast)

#### Part A: Main Analysis ####
# Read in Data
its1 <- read_sas("~/Desktop/Senior Statistician/Data Access/its_healthserviceuse.sas7bdat")

# | 1. Visually Inspect Data ####
# Ensure group is formatted as a factor for discrete coloring
its1$group_label <- factor(its1$group, levels = c(0, 1), labels = c("Control", "R2R"))
its1$group_time <- ifelse(its1$group == 1, its1$time, 0)
its1$group_level <- ifelse(its1$group == 1 & its1$level == 1, 1, 0)
its1$group_trend <-ifelse(its1$group_level == 1, its1$trend, 0)

exploratory_plot(
  data = its1, 
  outcome_var = ir_ed,
  title = "ED Visit Trends",
  y_label = "Incidence Rate (per 1,000 person-months)",
  y_limits = c(0, 50)
)

# | 2. Perform Preliminary Analysis ####
# a. A preliminary GLM regression
model01 <- glm(ir_hp ~ time + level + trend + group + group_time + group_level + group_trend, 
               data=its1, na.action = na.omit)
model02 <- glm(ir_ed ~ time + level + trend + group + group_time + group_level + group_trend, 
               data=its1, na.action = na.omit)
model03 <- glm(ir_op ~ time + level + trend + group + group_time + group_level + group_trend, 
               data=its1, na.action = na.omit)
# b. See summary of model output
summary(model01); summary(model02); summary(model03)

# | 3. Autocorrelation Plots ####
ac_plot_cits(reg_model = model01, data = its1, group_var = "group")

# | 4. Run the Final Model ####
# Fit the regression model with Newey-West standard error
nw_ip <- newey_reg_est(model01, floor(bwNeweyWest(model01))); nw_ip ## CHANGE LAG NUMBERS!!! ##
nw_ed <- newey_reg_est(model02, floor(bwNeweyWest(model02))); nw_ed ## CHANGE LAG NUMBERS!!! ##
nw_op <- newey_reg_est(model03, floor(bwNeweyWest(model03))); nw_op ## CHANGE LAG NUMBERS!!! ##

# | 5. Plot the Results ####
result_ip <- plot_cits(its1, model01, outcome_var = "ir_hp", outcome_text = "Incidence Rate (per 1,000 person-months)")
result_ip$plot

# | 6. Model Predicted Changes ####
pred_changes(result_ip, months = c(6, 11)) 
diff_ci(result_ip, model01, months = c(6, 11))

#### Part B: Sensitivity Analysis ####
# Execute automated pipeline
final_gls_model <- cits_gls(
  formula   = ir_hp ~ time + group + level + trend + group_level + group_trend,
  data      = its1,
  time_var  = "time",
  group_var = "group",
  max_p     = 3, # Evaluates AR(0), AR(1), AR(2)
  max_q     = 3  # Evaluates MA(0), MA(1)
)
summary(final_gls_model)

# End Script