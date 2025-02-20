#'Residual diagnostics for a fitted mvgam object
#'
#'This function takes a fitted \code{mvgam} object and returns various residual diagnostic plots
#'
#'@param object \code{list} object returned from \code{mvgam}
#'@param series \code{integer} specifying which series in the set is to be plotted
#'@param n_bins \code{integer} specifying the number of bins to use for binning fitted values
#'@param data_test Optional \code{dataframe} or \code{list} of test data containing at least 'series', 'y', and 'time'
#'in addition to any other variables included in the linear predictor of \code{formula}. If included, the
#'covariate information in \code{data_test} will be used to generate forecasts from the fitted model equations. If
#'this same \code{data_test} was originally included in the call to \code{mvgam}, then forecasts have already been
#'produced by the generative model and these will simply be extracted and used to calculate residuals.
#'However if no \code{data_test} was supplied to the original model call, an assumption is made that
#'the \code{data_test} supplied here comes sequentially after the data supplied as \code{data_train} in
#'the original model (i.e. we assume there is no time gap between the last
#'observation of series 1 in \code{data_train} and the first observation for series 1 in \code{data_test}).
#'@author Nicholas J Clark
#'@details A total of four base \code{R} plots are generated to examine Dunn-Smyth residuals for
#'the specified series. Plots include a residuals vs fitted values plot,
#'a Q-Q plot, and two plots to check for any remaining temporal autocorrelation in the residuals.
#'Note, all plots use posterior medians of fitted values / residuals, so uncertainty is not represented.
#'@return A series of base \code{R} plots
#'@export
plot_mvgam_resids = function(object, series = 1, n_bins = 25,
                             data_test){

  # Check arguments
  if(class(object) != 'mvgam'){
    stop('argument "object" must be of class "mvgam"')
  }

  if(sign(series) != 1){
    stop('argument "series" must be a positive integer',
         call. = FALSE)
  } else {
    if(series%%1 != 0){
      stop('argument "series" must be a positive integer',
           call. = FALSE)
    }
  }

  if(sign(n_bins) != 1){
    stop('argument "n_bins" must be a positive integer',
         call. = FALSE)
  } else {
    if(n_bins%%1 != 0){
      stop('argument "n_bins" must be a positive integer',
           call. = FALSE)
    }
  }

# Plotting colours
probs = c(0.05, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.95)
c_light <- c("#DCBCBC")
c_light_highlight <- c("#C79999")
c_mid <- c("#B97C7C")
c_mid_highlight <- c("#A25050")
c_dark <- c("#8F2727")
c_dark_highlight <- c("#7C0000")

# Prediction indices for the particular series
data_train <- object$obs_data
ends <- seq(0, dim(MCMCvis::MCMCchains(object$model_output, 'ypred'))[2],
            length.out = NCOL(object$ytimes) + 1)
starts <- ends + 1
starts <- c(1, starts[-c(1, (NCOL(object$ytimes)+1))])
ends <- ends[-1]

# Pull out series' residuals
series_residuals <- object$resids[[series]]

# Get indices of training horizon
if(class(data_train)[1] == 'list'){
  data_train_df <- data.frame(time = data_train$time,
                              y = data_train$y,
                              series = data_train$series)
  obs_length <- length(data_train_df %>%
                         dplyr::filter(series == !!(levels(data_train_df$series)[series])) %>%
                         dplyr::select(time, y) %>%
                         dplyr::distinct() %>%
                         dplyr::arrange(time) %>%
                         dplyr::pull(y))
} else {
  obs_length <- length(data_train %>%
                         dplyr::filter(series == !!(levels(data_train$series)[series])) %>%
                         dplyr::select(time, y) %>%
                         dplyr::distinct() %>%
                         dplyr::arrange(time) %>%
                         dplyr::pull(y))
}

if(missing(data_test)){
  # Resids and predictions for only the training period
  series_residuals <- series_residuals[, 1:obs_length]

  if(object$fit_engine == 'stan'){

    # For stan objects, ypred is stored as a vector in column-major order
    preds <- MCMCvis::MCMCchains(object$model_output, 'ypred')[,seq(series,
                                                                    dim(MCMCvis::MCMCchains(object$model_output, 'ypred'))[2],
                                                                    by = NCOL(object$ytimes))][, 1:obs_length]
  } else {
    preds <- MCMCvis::MCMCchains(object$model_output, 'ypred')[,starts[series]:ends[series]][, 1:obs_length]
  }

} else {

  if(object$fit_engine == 'stan'){

    # For stan objects, ypred is stored as a vector in column-major order
    preds <- MCMCvis::MCMCchains(object$model_output, 'ypred')[,seq(series,
                                                                    dim(MCMCvis::MCMCchains(object$model_output, 'ypred'))[2],
                                                                    by = NCOL(object$ytimes))]
  } else {
    preds <- MCMCvis::MCMCchains(object$model_output, 'ypred')[,starts[series]:ends[series]]
  }

  # Add variables to data_test if missing
  s_name <- levels(data_train$series)[series]
  if(!missing(data_test)){

    if(!'y' %in% names(data_test)){
      data_test$y <- rep(NA, NROW(data_test))
    }

    if(class(data_test)[1] == 'list'){
      if(!'time' %in% names(data_test)){
        stop('data_train does not contain a "time" column')
      }

      if(!'series' %in% names(data_test)){
        data_test$series <- factor('series1')
      }

    } else {
      if(!'time' %in% colnames(data_test)){
        stop('data_train does not contain a "time" column')
      }

      if(!'series' %in% colnames(data_test)){
        data_test$series <- factor('series1')
      }
    }
    # If the posterior predictions do not already cover the data_test period, the forecast needs to be
    # generated using the latent trend dynamics; note, this assumes that there is no gap between the training and
    # testing datasets
    if(class(data_train)[1] == 'list'){
      all_obs <- c(data.frame(y = data_train$y,
                              series = data_train$series,
                              time = data_train$time) %>%
                     dplyr::filter(series == s_name) %>%
                     dplyr::select(time, y) %>%
                     dplyr::distinct() %>%
                     dplyr::arrange(time) %>%
                     dplyr::pull(y),
                   data.frame(y = data_test$y,
                              series = data_test$series,
                              time = data_test$time) %>%
                     dplyr::filter(series == s_name) %>%
                     dplyr::select(time, y) %>%
                     dplyr::distinct() %>%
                     dplyr::arrange(time) %>%
                     dplyr::pull(y))
    } else {
      all_obs <- c(data_train %>%
                     dplyr::filter(series == s_name) %>%
                     dplyr::select(time, y) %>%
                     dplyr::distinct() %>%
                     dplyr::arrange(time) %>%
                     dplyr::pull(y),
                   data_test %>%
                     dplyr::filter(series == s_name) %>%
                     dplyr::select(time, y) %>%
                     dplyr::distinct() %>%
                     dplyr::arrange(time) %>%
                     dplyr::pull(y))
    }

    if(dim(preds)[2] != length(all_obs)){
      fc_preds <- forecast.mvgam(object, series = series, data_test = data_test)
      preds <- cbind(preds, fc_preds)
    }

    # Calculate out of sample residuals
    preds <- preds[,tail(1:dim(preds)[2], length(data_test$time))]
    truth <- data_test$y

    # Functions for calculating randomised quantile (Dunn-Smyth) residuals
    ds_resids_nb = function(truth, fitted, draw, size){
      dsres_out <- matrix(NA, length(truth), 1)
      for(i in 1:length(truth)){
        if(is.na(truth[i])){
          a <- pnbinom(as.vector(draw[i]) - 1, mu = fitted[i], size = size)
          b <- pnbinom(as.vector(draw[i]), mu = fitted[i], size = size)
        } else {
          a <- pnbinom(as.vector(truth[i]) - 1, mu = fitted[i], size = size)
          b <- pnbinom(as.vector(truth[i]), mu = fitted[i], size = size)
        }

        u <- runif(n = 1, min = a, max = b)
        if(u <= 0){
          u <- runif(n = 1, min = 0.0000001, max = 0.01)
        }
        if(u >=1){
          u <- runif(n = 1, min = 0.99, max = 0.9999999)
        }
        dsres_out[i, ] <- qnorm(u)
      }
      resids <- dsres_out[,1]
      resids[is.infinite(resids)] <- NaN
      resids
    }

    ds_resids_pois = function(truth, fitted, draw){
      dsres_out <- matrix(NA, length(truth), 1)
      for(i in 1:length(truth)){
        if(is.na(truth[i])){
          a <- ppois(as.vector(draw[i]) - 1, lambda = fitted[i])
          b <- ppois(as.vector(draw[i]), lambda = fitted[i])
        } else {
          a <- ppois(as.vector(truth[i]) - 1, lambda = fitted[i])
          b <- ppois(as.vector(truth[i]), lambda = fitted[i])
        }

        u <- runif(n = 1, min = a, max = b)
        if(u <= 0){
          u <- runif(n = 1, min = 0.0000001, max = 0.01)
        }
        if(u >=1){
          u <- runif(n = 1, min = 0.99, max = 0.9999999)
        }
        dsres_out[i, ] <- qnorm(u)
      }
      resids <- dsres_out[,1]
      resids[is.infinite(resids)] <- NaN
      resids
    }

    ds_resids_tw = function(truth, fitted, draw){
      dsres_out <- matrix(NA, length(truth), 1)
      for(i in 1:length(truth)){
        if(is.na(truth[i])){
          a <- ppois(as.vector(draw[i]) - 1, lambda = fitted[i])
          b <- ppois(as.vector(draw[i]), lambda = fitted[i])
        } else {
          a <- ppois(as.vector(truth[i]) - 1, lambda = fitted[i])
          b <- ppois(as.vector(truth[i]), lambda = fitted[i])
        }

        u <- runif(n = 1, min = a, max = b)
        if(u <= 0){
          u <- runif(n = 1, min = 0.0000001, max = 0.01)
        }
        if(u >=1){
          u <- runif(n = 1, min = 0.99, max = 0.9999999)
        }
        dsres_out[i, ] <- qnorm(u)
      }
      resids <- dsres_out[,1]
      resids[is.infinite(resids)] <- NaN
      resids
    }

   n_obs <- length(truth)

   if(NROW(preds) > 2000){
     sample_seq <- sample(1:NROW(preds), 2000, F)
   } else {
     sample_seq <- 1:NROW(preds)
   }

   if(object$family == 'Poisson'){
     resids <- do.call(rbind, lapply(sample_seq, function(x){
       suppressWarnings(ds_resids_pois(truth = truth,
                                       fitted = preds[x, ],
                                       draw = preds[x, ]))
     }))
   }

   if(object$family == 'Negative Binomial'){
     size <- MCMCvis::MCMCchains(object$model_output, 'r')[,series]
     resids <- do.call(rbind, lapply(sample_seq, function(x){
       suppressWarnings(ds_resids_nb(truth = truth,
                                     fitted = preds[x, ],
                                     draw = preds[x, ],
                                     size = size[x]))
     }))
   }

   if(object$family == 'Tweedie'){
     resids <- do.call(rbind, lapply(sample_seq, function(x){
       suppressWarnings(ds_resids_tw(truth = truth,
                                     fitted = preds[x, ],
                                     draw = preds[x, ]))
     }))
  }
  }
}

median_preds <- apply(preds, 2, function(x) quantile(x, 0.5))

# Graphical parameters
layout(matrix(1:4, ncol = 2, nrow = 2, byrow = TRUE))

# Fitted vs redisuals plot
n_fitted_bins = n_bins

# Get x-axis values and bin if necessary to prevent overplotting
sorted_x <- sort(unique(round(median_preds, 6)))

if(length(sorted_x) > n_fitted_bins){
  sorted_x <- seq(min(sorted_x), max(sorted_x), length.out = n_fitted_bins)
  resid_probs <- do.call(rbind, lapply(2:n_fitted_bins, function(i){
    quantile(as.vector(series_residuals[,which(round(median_preds, 6) <= sorted_x[i] &
                                               round(median_preds, 6) > sorted_x[i-1])]),
             probs = probs)
  }))
  resid_probs <- rbind(quantile(as.vector(series_residuals[,which(round(median_preds, 6) == sorted_x[1])]),
                                probs = probs),
                       resid_probs)

} else {
  resid_probs <- do.call(rbind, lapply(sorted_x, function(i){
    quantile(as.vector(series_residuals[,which(round(median_preds, 6) == i)]),
             probs = probs)
  }))
}

# Get polygon coordinates and plot
N <- length(sorted_x)
idx <- rep(1:N, each = 2)
repped_x <- rep(sorted_x, each = 2)

x <- sapply(1:length(idx),
            function(k) if(k %% 2 == 0)
              repped_x[k] + min(diff(sorted_x))/2 else
                repped_x[k] - min(diff(sorted_x))/2)

# Plot
plot(median_preds[1:length(object$resids[[series]])],
     object$resids[[series]],
     bty = 'L',
     xlab = 'Fitted values',
     ylab = 'DS residuals',
     pch = 16,
     col = 'white',
     cex = 1,
     ylim = range(resid_probs, na.rm = T))
title('Resids vs Fitted Values', line = 0)

rect(xleft = x[seq(1, N*2, by = 2)],
     xright = x[seq(2, N*2, by = 2)],
     ytop =  resid_probs[,9],
     ybottom =  resid_probs[,1],
     col = c_light,
     border = 'transparent')
rect(xleft = x[seq(1, N*2, by = 2)],
     xright = x[seq(2, N*2, by = 2)],
     ytop =  resid_probs[,8],
     ybottom =  resid_probs[,2],
     col = c_light_highlight,
     border = 'transparent')
rect(xleft = x[seq(1, N*2, by = 2)],
     xright = x[seq(2, N*2, by = 2)],
     ytop =  resid_probs[,7],
     ybottom =  resid_probs[,3],
     col = c_mid,
     border = 'transparent')
rect(xleft = x[seq(1, N*2, by = 2)],
     xright = x[seq(2, N*2, by = 2)],
     ytop =  resid_probs[,6],
     ybottom =  resid_probs[,4],
     col = c_mid_highlight,
     border = 'transparent')

for (k in 1:N) {
  lines(x = c(x[seq(1, N*2, by = 2)][k],x[seq(2, N*2, by = 2)][k]),
        y = c(resid_probs[k,5], resid_probs[k,5]),
        col = c_dark, lwd = 2)
}
abline(h = 0, col = '#FFFFFF60', lwd = 2.85)
abline(h = 0, col = 'black', lwd = 2.5, lty = 'dashed')

# Q-Q plot
coords <- qqnorm(series_residuals[1,], plot.it = F)
resid_coords_y <- matrix(NA, nrow = NROW(series_residuals), ncol = length(coords$y))
for(i in 1:NROW(series_residuals)){
  norm_coords <- qqnorm(series_residuals[i,], plot.it = F)
  coords_y <- norm_coords$y
  coords_y[abs(coords_y) > 3.75] <- NA
  resid_coords_y[i,] <- coords_y[order(norm_coords$x)]
}

cred <- sapply(1:NCOL(resid_coords_y),
               function(n) quantile(resid_coords_y[,n],
                                    probs = probs,
                                    na.rm = T))
pred_vals <- coords$x[order(coords$x)]
pred_vals <- pred_vals[complete.cases(cred[1,])]
plot(x = pred_vals,
     y = cred[5,][complete.cases(cred[1,])],
     bty = 'L',
     xlab = 'Theoretical Quantiles',
     ylab = 'Sample Quantiles',
     pch = 16,
     col = 'white',
     cex = 1,
     ylim = range(cred, na.rm = T),
     tck = -0.04)
title('Normal Q-Q Plot', line = 0)
polygon(c(pred_vals, rev(pred_vals)), c(cred[1,][complete.cases(cred[1,])],
                                        rev(cred[9,][complete.cases(cred[1,])])),
        col = c_light, border = NA)
polygon(c(pred_vals, rev(pred_vals)), c(cred[2,][complete.cases(cred[1,])],
                                        rev(cred[8,][complete.cases(cred[1,])])),
        col = c_light_highlight, border = NA)
polygon(c(pred_vals, rev(pred_vals)), c(cred[3,][complete.cases(cred[1,])],
                                        rev(cred[7,][complete.cases(cred[1,])])),
        col = c_mid, border = NA)
polygon(c(pred_vals, rev(pred_vals)), c(cred[4,][complete.cases(cred[1,])],
                                        rev(cred[6,][complete.cases(cred[1,])])),
        col = c_mid_highlight, border = NA)
lines(pred_vals, cred[5,][complete.cases(cred[1,])], col = c_dark, lwd = 2.5)
qqline(cred[5,][complete.cases(cred[1,])], col = '#FFFFFF60', lwd = 3)
qqline(cred[5,][complete.cases(cred[1,])], col = 'black', lwd = 2.5)

# ACF plot
acf1 <- acf(series_residuals[1,], plot = F,
            na.action = na.pass)
resid_acf <- matrix(NA, nrow = NROW(series_residuals),
                    ncol = length(acf1$acf[,,1]))
for(i in 1:NROW(series_residuals)){
  resid_acf[i, ] <- acf(series_residuals[i,], plot = F,
                        na.action = na.pass)$acf[,,1]
}

sorted_x <- seq(1:NCOL(resid_acf))
N <- length(sorted_x)
idx <- rep(1:N, each = 2)
repped_x <- rep(sorted_x, each = 2)

x <- sapply(1:length(idx),
            function(k) if(k %% 2 == 0)
              repped_x[k] + min(diff(sorted_x))/2 else
                repped_x[k] - min(diff(sorted_x))/2)
cred <- sapply(1:NCOL(resid_acf),
               function(n) quantile(resid_acf[,n],
                                    probs = probs, na.rm = T))
cred <- cred[, -1]
clim <- qnorm((1 + .95)/2)/sqrt(acf1$n.used)
plot(1, type = "n", bty = 'L',
     xlab = 'Lag',
     ylab = 'Autocorrelation',
     xlim = c(1, N-1),
     xaxt = 'n',
     ylim = range(c(cred,
                    -clim - 0.05,
                    clim + 0.05)))
axis(1, at = seq(1, NCOL(cred), by = 2))
title('ACF', line = 0)

N <- N - 1
rect(xleft = x[seq(1, N*2, by = 2)],
     xright = x[seq(2, N*2, by = 2)],
     ytop =  cred[9,],
     ybottom =  cred[1,],
     col = c_light,
     border = 'transparent')
rect(xleft = x[seq(1, N*2, by = 2)],
     xright = x[seq(2, N*2, by = 2)],
     ytop =  cred[8,],
     ybottom =  cred[2,],
     col = c_light_highlight,
     border = 'transparent')
rect(xleft = x[seq(1, N*2, by = 2)],
     xright = x[seq(2, N*2, by = 2)],
     ytop =  cred[7,],
     ybottom =  cred[3,],
     col = c_mid,
     border = 'transparent')
rect(xleft = x[seq(1, N*2, by = 2)],
     xright = x[seq(2, N*2, by = 2)],
     ytop =  cred[6,],
     ybottom =  cred[4,],
     col = c_mid_highlight,
     border = 'transparent')

for (k in 1:N) {
  lines(x = c(x[seq(1, N*2, by = 2)][k],x[seq(2, N*2, by = 2)][k]),
        y = c(cred[5,k], cred[5,k]),
        col = c_dark, lwd = 2)
}
abline(h = clim,  col = '#FFFFFF60', lwd = 2.85)
abline(h = clim,  col = 'black', lwd = 2.5, lty = 'dashed')
abline(h = -clim,  col = '#FFFFFF60', lwd = 2.85)
abline(h = -clim, col = 'black', lwd = 2.5, lty = 'dashed')

# PACF plot
pacf1 <- pacf(series_residuals[1,], plot = F,
            na.action = na.pass)
resid_pacf <- matrix(NA, nrow = NROW(series_residuals),
                    ncol = length(pacf1$acf[,,1]))
for(i in 1:NROW(series_residuals)){
  resid_pacf[i, ] <- pacf(series_residuals[i,], plot = F,
                        na.action = na.pass)$acf[,,1]
}

sorted_x <- seq(1:NCOL(resid_pacf))
N <- length(sorted_x)
idx <- rep(1:N, each = 2)
repped_x <- rep(sorted_x, each = 2)

x <- sapply(1:length(idx),
            function(k) if(k %% 2 == 0)
              repped_x[k] + min(diff(sorted_x))/2 else
                repped_x[k] - min(diff(sorted_x))/2)
cred <- sapply(1:NCOL(resid_pacf),
               function(n) quantile(resid_pacf[,n],
                                    probs = probs, na.rm = T))

clim <- qnorm((1 + .95)/2)/sqrt(pacf1$n.used)
plot(1, type = "n", bty = 'L',
     xlab = 'Lag',
     ylab = 'Autocorrelation',
     xlim = c(1, length(sorted_x)),
     xaxt = 'n',
     ylim = range(c(cred,
                    -clim - 0.05,
                    clim + 0.05)))
axis(1, at = seq(1, NCOL(cred), by = 2))
title('pACF', line = 0)

rect(xleft = x[seq(1, N*2, by = 2)],
     xright = x[seq(2, N*2, by = 2)],
     ytop =  cred[9,],
     ybottom =  cred[1,],
     col = c_light,
     border = 'transparent')
rect(xleft = x[seq(1, N*2, by = 2)],
     xright = x[seq(2, N*2, by = 2)],
     ytop =  cred[8,],
     ybottom =  cred[2,],
     col = c_light_highlight,
     border = 'transparent')
rect(xleft = x[seq(1, N*2, by = 2)],
     xright = x[seq(2, N*2, by = 2)],
     ytop =  cred[7,],
     ybottom =  cred[3,],
     col = c_mid,
     border = 'transparent')
rect(xleft = x[seq(1, N*2, by = 2)],
     xright = x[seq(2, N*2, by = 2)],
     ytop =  cred[6,],
     ybottom =  cred[4,],
     col = c_mid_highlight,
     border = 'transparent')

for (k in 1:N) {
  lines(x = c(x[seq(1, N*2, by = 2)][k],x[seq(2, N*2, by = 2)][k]),
        y = c(cred[5,k], cred[5,k]),
        col = c_dark, lwd = 2)
}
abline(h = clim, col = '#FFFFFF60', lwd = 2.85)
abline(h = clim, col = 'black', lwd = 2.5, lty = 'dashed')
abline(h = -clim, col = '#FFFFFF60', lwd = 2.85)
abline(h = -clim, col = 'black', lwd = 2.5, lty = 'dashed')
layout(1)

}
