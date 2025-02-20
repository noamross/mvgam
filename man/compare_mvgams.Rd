% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/compare_mvgams.R
\name{compare_mvgams}
\alias{compare_mvgams}
\title{Compare fitted mvgam objects for model selection using rolling forecast evaluations}
\usage{
compare_mvgams(
  model1,
  model2,
  n_samples = 1000,
  fc_horizon = 3,
  n_evaluations = 10,
  n_cores = 2
)
}
\arguments{
\item{model1}{\code{list} object returned from \code{mvgam} representing the first model to be
evaluated}

\item{model2}{\code{list} object returned from \code{mvgam} representing the second model to be
evaluated}

\item{n_samples}{\code{integer} specifying the number of samples to generate from the model's
posterior distribution}

\item{fc_horizon}{\code{integer} specifying the length of the forecast horizon for evaluating forecasts}

\item{n_evaluations}{\code{integer} specifying the total number of evaluations to perform}

\item{n_cores}{\code{integer} specifying number of cores for generating particle forecasts in parallel}
}
\value{
A series of plots comparing forecast Discrete Rank Probability Scores (DRPS) for each competing
model. A lower DRPS is preferred. Note however that it is possible to select a model that ultimately
would perform poorly in true out-of-sample forecasting. For example if a wiggly smooth function of 'year'
is included in the model then this function will be learned prior to evaluating rolling window forecasts,
and the model could generate very tight predictions as a result. But when forecasting ahead to timepoints
that the model has not seen (i.e. next year), the smooth function will end up extrapolating, sometimes
in very strange and unexpected ways. It is therefore recommended to only use smooth functions for
covariates that are adequately measured in the data (i.e. 'seasonality', for example) to reduce possible
extrapolation of smooths and let the latent trends in the \code{mvgam} model capture any
temporal dependencies in the data. These trends are time series models and so will provide much more
stable forecasts
}
\description{
This function compares two fitted models using rolling window forecast evaluation and
provides a series of summary plots to facilitate model selection. It is essentially a wrapper for
\code{roll_eval_mvgam}
}
\seealso{
\code{roll_eval_mvgam}, \code{eval_mvgam}
}
