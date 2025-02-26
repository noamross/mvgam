% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/forecast.mvgam.R
\name{forecast.mvgam}
\alias{forecast.mvgam}
\title{Compute out of sample forecasts for a fitted \code{mvgam} object}
\usage{
\method{forecast}{mvgam}(object, data_test, series = 1, type = "response")
}
\arguments{
\item{object}{\code{list} object returned from \code{mvgam}}

\item{data_test}{A \code{dataframe} or \code{list} of test data containing at least 'series' and 'time'
for the forecast horizon, in addition to any other variables included in the linear predictor of \code{formula}.
The covariate information in \code{data_test} will be used to generate forecasts from the fitted model equations. If
this same \code{data_test} was originally included in the call to \code{mvgam}, then forecasts have already been
produced by the generative model and these will simply be extracted. However if no \code{data_test} was
supplied to the original model call, an assumption is made that the \code{data_test} supplied here comes sequentially
after the data supplied as \code{data_train} in the original model (i.e. we assume there is no time gap between the last
observation of series 1 in \code{data_train} and the first observation for series 1 in \code{data_test}).}

\item{series}{\code{integer} specifying which series in the set is to be forecast}

\item{type}{When this has the value \code{link}, the linear predictor is calculated on the log link scale.
When \code{response} is used, the predictions take uncertainty in the observation process into account to return
predictions on the outcome (discrete) scale (default). When \code{trend} is used, only the forecast distribution for the
latent trend is returned.}
}
\value{
A \code{matrix} of the forecast distribution
}
\description{
Compute out of sample forecasts for a fitted \code{mvgam} object
}
\details{
Posterior predictions are drawn from the fitted \code{mvgam} and used to simulate a forecast distribution
}
