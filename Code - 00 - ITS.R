# Jihoon Lim
# ITS Functions
# August 24, 2026

#### Exploratory Plot ####
exploratory_plot <- function(data, 
                             outcome_var, 
                             title = "Hospitalization Trends",
                             y_label = "Incidence Rate",
                             y_limits = c(0, 30)) {
  
  # Ensure group_label is clean for custom color matching
  # Assumes 'group' column exists (0 = Control, 1 = R2R)
  if (!"group_label" %in% names(data)) {
    data$group_label <- factor(data$group, 
                               levels = c(0, 1), 
                               labels = c("Control", "R2R"))
  }
  
  ggplot(data, aes(x = time, y = {{ outcome_var }}, color = group_label, group = group_label)) +
    # Points and fitted lines
    geom_point(size = 2) +
    geom_line(linewidth = 0.8) +
    
    # Vertical reference line for implementation at Relative Month 0
    geom_vline(xintercept = 0, linetype = "dashed", color = "gray30") +
    
    # X-axis tick marks and relative time labels (-12 to +11)
    scale_x_continuous(
      breaks = seq(-12, 11, by = 2),
      labels = seq(-12, 11, by = 2),
      limits = c(-12, 11)
    ) +
    
    # Dynamic Y-axis scaling
    scale_y_continuous(limits = y_limits) +
    
    # Publication color palette
    scale_color_manual(values = c("Control" = "navy", "R2R" = "firebrick")) +
    
    # Titles and axis labels
    labs(
      title = title,
      x = "Relative Months to Implementation",
      y = y_label,
      color = "Cohort Group"
    ) +
    
    # Publication theme
    theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold", hjust = 0.5),
      legend.position = "bottom",
      panel.grid.minor = element_blank()
    )
}

#### Residual Plot ####
res_plot <- function(dataset, reg_model) {
  plot(dataset$time[1:length(dataset$time)], residuals(reg_model)[1:length(dataset$time)], 
       type='o', pch=16, main = "Residual Plot", 
       xlab='Time', ylab='Residuals', col="red")
  abline(h=0, lty=2)
}

#### Autocorrelation Plots ####
ac_plot_cits <- function(reg_model, data, group_var = "group") {
  # Save original graphics layout parameters
  old_par <- par(no.readonly = TRUE)
  on.exit(par(old_par))
  
  # Attach residuals to a copy of the dataset
  df <- data
  df$res <- residuals(reg_model)
  
  # Set up a 3x2 grid layout (Rows: Full, Treatment, Control | Cols: ACF, PACF)
  par(mfrow = c(3, 2), mar = c(4, 4, 3, 1))
  
  # 1. Full Model Residuals
  acf(df$res, main = "Full Model: ACF")
  acf(df$res, type = "partial", main = "Full Model: PACF")
  
  # 2. Treatment Group (group == 1)
  res_trt <- df$res[df[[group_var]] == 1]
  acf(res_trt, main = "Treatment (Group 1): ACF")
  acf(res_trt, type = "partial", main = "Treatment (Group 1): PACF")
  
  # 3. Control Group (group == 0)
  res_ctrl <- df$res[df[[group_var]] == 0]
  acf(res_ctrl, main = "Control (Group 0): ACF")
  acf(res_ctrl, type = "partial", main = "Control (Group 0): PACF")
}

#### Newey-West Adjustments ####
newey_reg_est <- function(reg_model, lag_number) {
  nw.reg <- coeftest(reg_model, vcov=NeweyWest(reg_model, lag=lag_number))
  nw.est <- matrix(data = NA, nrow = 8, ncol = 5)
  for (i in 1:8) { # Number of coefficients in the regression model
    ar.vcov <- NeweyWest(reg_model, lag=lag_number)
    nw.se <- sqrt(ar.vcov[i, i])
    nw.point <- round(coef(nw.reg)[i], 2)
    nw.lower <- round(coef(nw.reg)[i] - nw.se*1.96, 2)
    nw.upper <- round(coef(nw.reg)[i] + nw.se*1.96, 2)
    nw.pval <- round(nw.reg[,4][[i]], 4)
    nw.est[i,] <- cbind(nw.point, nw.se, nw.lower, nw.upper, nw.pval)
  }
  return(nw.est)
}

#### Main Figure Labels ####
plot_cits <- function(data, model, outcome_var, outcome_text,
                      time_var = "time", group_var = "group",
                      treat_val = 1, control_val = 0) {
  
  # Fitted values on the full data (regression itself unaffected)
  data <- data %>% mutate(.fitted = predict(model, type = "response", newdata = data))
  
  # Counterfactual for the treatment group (full data)
  cf <- data %>%
    filter(.data[[group_var]] == treat_val) %>%
    mutate(group_level = 0, group_trend = 0)
  cf$.cf <- predict(model, type = "response", newdata = cf)
  
  p <- ggplot() +
    geom_point(data = data,
               aes(x = .data[[time_var]], y = .data[[outcome_var]],
                   color = factor(.data[[group_var]])), alpha = 0.4) +
    
    geom_line(data = filter(data, .data[[group_var]] == treat_val, .data[[time_var]] < 0),
              aes(x = .data[[time_var]], y = .fitted), color = "firebrick", linewidth = 1) +
    geom_line(data = filter(data, .data[[group_var]] == treat_val, .data[[time_var]] > 0),
              aes(x = .data[[time_var]], y = .fitted), color = "firebrick", linewidth = 1) +
    
    geom_line(data = filter(data, .data[[group_var]] == control_val, .data[[time_var]] < 0),
              aes(x = .data[[time_var]], y = .fitted), color = "steelblue", linewidth = 1) +
    geom_line(data = filter(data, .data[[group_var]] == control_val, .data[[time_var]] > 0),
              aes(x = .data[[time_var]], y = .fitted), color = "steelblue", linewidth = 1) +
    
    geom_line(data = filter(cf, .data[[time_var]] > 0),
              aes(x = .data[[time_var]], y = .cf),
              color = "firebrick", linetype = "dashed", linewidth = 1) +
    
    geom_vline(xintercept = 0, linetype = "dotted") +
    scale_color_manual(values = c("steelblue", "firebrick"),
                       labels = c("Control", "Treatment"), name = "Group") +
    labs(x = "Time relative to intervention", y = outcome_text) +
    theme_minimal(base_size = 13)
  
  # Return everything downstream functions might need
  list(plot = p, data = data, counterfactual = cf,
       time_var = time_var, group_var = group_var, treat_val = treat_val)
}

#### Fit GLS ####
cits_gls <- function(formula, data, time_var = "time", group_var = "group", max_p = 2, max_q = 1) {
  
  cat("=====================================================\n")
  cat("   AUTOMATED CITS GLS LAG SELECTION & ESTIMATION     \n")
  cat("=====================================================\n\n")
  
  # 1. Construct correlation formula dynamically: ~ time | group
  corr_formula <- as.formula(paste0("~ ", time_var, " | ", group_var))
  
  # 2. Fit baseline independence model (OLS equivalent via GLS)
  cat("--> Fitting baseline model (No Autocorrelation)...\n")
  models <- list()
  model_names <- c("Independence (No ARMA)")
  
  models[[1]] <- gls(formula, data = data, method = "ML")
  
  # 3. Grid search across ARMA(p, q) combinations using ML
  for (p in 0:max_p) {
    for (q in 0:max_q) {
      if (p == 0 && q == 0) next # Skip baseline
      
      name <- paste0("ARMA(", p, ",", q, ")")
      cat(paste0("--> Fitting ", name, "...\n"))
      
      tryCatch({
        if (q == 0) {
          # Use corAR1 for simple AR(1) for speed/stability, corARMA for p > 1
          if (p == 1) {
            fit <- gls(formula, correlation = corAR1(form = corr_formula), data = data, method = "ML")
          } else {
            fit <- gls(formula, correlation = corARMA(form = corr_formula, p = p, q = 0), data = data, method = "ML")
          }
        } else {
          fit <- gls(formula, correlation = corARMA(form = corr_formula, p = p, q = q), data = data, method = "ML")
        }
        models[[length(models) + 1]] <- fit
        model_names <- c(model_names, name)
      }, error = function(e) {
        cat(paste0("    [Warning] ", name, " failed to converge. Skipped.\n"))
      })
    }
  }
  
  names(models) <- model_names
  
  # 4. Compare Information Criteria (AIC & BIC)
  aic_table <- data.frame(
    Model = model_names,
    AIC   = sapply(models, AIC),
    BIC   = sapply(models, BIC),
    logLik = sapply(models, logLik)
  )
  aic_table <- aic_table[order(aic_table$AIC), ] # Sort by lowest AIC
  
  cat("\n--- Model Selection Table (Sorted by AIC) ---\n")
  print(aic_table, row.names = FALSE)
  
  # 5. Identify Best Model by AIC
  best_model_name <- aic_table$Model[1]
  cat(paste0("\n--> Best Performing Structure by AIC: ", best_model_name, "\n"))
  
  # 6. Run Likelihood Ratio Test (LRT) against baseline
  cat("\n--- Likelihood Ratio Test vs. Baseline ---\n")
  lrt_res <- anova(models[["Independence (No ARMA)"]], models[[best_model_name]])
  print(lrt_res)
  
  # 7. Refit Best Model using REML for final parameter estimation
  cat(paste0("\n--> Refitting final ", best_model_name, " model using REML...\n"))
  best_fit_ml <- models[[best_model_name]]
  
  if (best_model_name == "Independence (No ARMA)") {
    final_reml <- gls(formula, data = data, method = "REML")
  } else {
    # Extract correlation structure from ML model and re-apply to REML
    corr_struct <- best_fit_ml$modelStruct$corStruct
    final_reml <- gls(formula, correlation = corr_struct, data = data, method = "REML")
  }
  
  # 8. Plot Diagnostic ACF/PACF of Final REML Normalized Residuals
  cat("--> Generating residual diagnostic plots...\n")
  old_par <- par(no.readonly = TRUE)
  on.exit(par(old_par))
  
  par(mfrow = c(2, 1), mar = c(4, 4, 3, 1))
  norm_res <- residuals(final_reml, type = "normalized")
  acf(norm_res, main = paste0("Final Model (", best_model_name, " REML): Normalized Residual ACF"))
  pacf(norm_res, main = paste0("Final Model (", best_model_name, " REML): Normalized Residual PACF"))
  
  cat("\n=====================================================\n")
  cat("   SELECTION COMPLETE: Returning REML Model Object    \n")
  cat("=====================================================\n")
  
  return(final_reml)
}

#### Predictive Changes ####
pred_changes <- function(cits_output, months = c(6, 12)) {
  
  time_var  <- cits_output$time_var
  group_var <- cits_output$group_var
  treat_val <- cits_output$treat_val
  
  # Predicted (observed/fitted) values for the TREATMENT group at the requested months
  pred_df <- cits_output$data %>%
    filter(.data[[group_var]] == treat_val, .data[[time_var]] %in% months) %>%
    arrange(.data[[time_var]]) %>%
    select(!!time_var := all_of(time_var), predicted = .fitted)
  
  # Counterfactual values at the same months
  cfac_df <- cits_output$counterfactual %>%
    filter(.data[[time_var]] %in% months) %>%
    arrange(.data[[time_var]]) %>%
    select(!!time_var := all_of(time_var), counterfactual = .cf)
  
  # Join on time so rows are guaranteed to line up correctly
  out <- inner_join(pred_df, cfac_df, by = time_var) %>%
    mutate(abs.change = predicted - counterfactual,
           rel.change = (predicted - counterfactual) / counterfactual)
  
  if (nrow(out) < length(months)) {
    missing <- setdiff(months, out[[time_var]])
    warning("No matching rows found for time = ", paste(missing, collapse = ", "))
  }
  out
}

#### 95% CI around Absolute and Relative Differences ####
diff_ci <- function(cits_output, model, months = c(6, 12), conf_level = 0.95) {
  
  time_var  <- cits_output$time_var
  group_var <- cits_output$group_var
  treat_val <- cits_output$treat_val
  
  # Treatment-group rows at the requested months
  rows <- cits_output$data %>%
    filter(.data[[group_var]] == treat_val, .data[[time_var]] %in% months) %>%
    arrange(.data[[time_var]])
  
  if (nrow(rows) < length(months)) {
    missing <- setdiff(months, rows[[time_var]])
    warning("No matching treatment-group rows for time = ", paste(missing, collapse = ", "))
  }
  
  # Controlled counterfactual: zero out the DIFFERENTIAL intervention terms only
  # (change to level = 0, trend = 0 instead if you want the uncontrolled/naive counterfactual)
  rows_cf <- rows %>% mutate(group_level = 0, group_trend = 0)
  
  # Design matrices built from the model's own formula, so columns always match beta exactly
  tt    <- delete.response(terms(model))
  X_obs <- model.matrix(tt, data = rows)
  X_cfl <- model.matrix(tt, data = rows_cf)
  
  beta <- coef(model)
  obs  <- as.numeric(X_obs %*% beta)
  cfl  <- as.numeric(X_cfl %*% beta)
  
  # HAC covariance matrix of coefficients
  vc <- NeweyWest(model, lag = floor(bwNeweyWest(model)), prewhite = FALSE)
  
  # --- Absolute difference: delta method on the DIFFERENCE row directly ---
  X_diff   <- X_obs - X_cfl
  abs_diff <- as.numeric(X_diff %*% beta)        # equals obs - cfl
  se_abs   <- sqrt(rowSums((X_diff %*% vc) * X_diff))
  
  # --- Relative difference: rel = obs/cfl - 1, delta method with covariance ---
  var_obs      <- rowSums((X_obs %*% vc) * X_obs)
  var_cfl      <- rowSums((X_cfl %*% vc) * X_cfl)
  cov_obs_cfl  <- rowSums((X_obs %*% vc) * X_cfl)
  
  rel_diff <- obs / cfl - 1
  g_obs    <- 1 / cfl
  g_cfl    <- -obs / cfl^2
  se_rel   <- sqrt(g_obs^2 * var_obs + g_cfl^2 * var_cfl + 2 * g_obs * g_cfl * cov_obs_cfl)
  
  z <- qt(1 - (1 - conf_level) / 2, df = model$df.residual)
  
  tibble(
    !!time_var := rows[[time_var]],
    observed        = obs,
    counterfactual  = cfl,
    abs.diff        = abs_diff,
    abs.lower       = abs_diff - z * se_abs,
    abs.upper       = abs_diff + z * se_abs,
    rel.diff        = rel_diff,
    rel.lower       = rel_diff - z * se_rel,
    rel.upper       = rel_diff + z * se_rel
  )
}
