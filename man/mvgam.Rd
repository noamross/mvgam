% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mvgam.R
\name{mvgam}
\alias{mvgam}
\title{Fit a Bayesian dynamic GAM to a univariate or multivariate set of discrete time series}
\usage{
mvgam(
  formula,
  knots,
  data_train,
  data_test,
  run_model = TRUE,
  prior_simulation = FALSE,
  return_model_data = FALSE,
  family = "poisson",
  use_lv = FALSE,
  n_lv,
  trend_model = "RW",
  drift = FALSE,
  chains = 4,
  burnin = 1000,
  n_samples = 1000,
  thin = 1,
  parallel = TRUE,
  phi_prior,
  ar_prior,
  r_prior,
  twdis_prior,
  sigma_prior,
  lambda_prior,
  rho_gp_prior,
  alpha_gp_prior,
  upper_bounds,
  use_stan = FALSE,
  max_treedepth,
  adapt_delta,
  jags_path
)
}
\arguments{
\item{formula}{A \code{character} string specifying the GAM formula. These are exactly like the formula
for a GLM except that smooth terms, s, te, ti and t2, can be added to the right hand side
to specify that the linear predictor depends on smooth functions of predictors (or linear functionals of these).}

\item{knots}{An optional \code{list} containing user specified knot values to be used for basis construction.
For most bases the user simply supplies the knots to be used, which must match up with the k value supplied
(note that the number of knots is not always just k). Different terms can use different numbers of knots,
unless they share a covariate.}

\item{data_train}{A \code{dataframe} or \code{list} containing the model response variable and covariates
required by the GAM \code{formula}. Should include columns:
'y' (the discrete outcomes; \code{NA}s allowed)
'series' (character or factor index of the series IDs)
'time' (numeric index of the time point for each observation).
Any other variables to be included in the linear predictor of \code{formula} must also be present}

\item{data_test}{Optional \code{dataframe} or \code{list} of test data containing at least 'series' and 'time'
in addition to any other variables included in the linear predictor of \code{formula}. If included, the
observations in \code{data_test} will be set to \code{NA} when fitting the model so that posterior
simulations can be obtained}

\item{run_model}{\code{logical}. If \code{FALSE}, the model is not fitted but instead the function will
return the model file and the data / initial values that are needed to fit the model outside of \code{mvgam}}

\item{prior_simulation}{\code{logical}. If \code{TRUE}, no observations are fed to the model, and instead
simulations from prior distributions are returned}

\item{return_model_data}{\code{logical}. If \code{TRUE}, the list of data that is needed to fit the
model is returned, along with the initial values for smooth and AR parameters, once the model is fitted.
This will be helpful if users wish to modify the model file to add
other stochastic elements that are not currently avaiable in \code{mvgam}. Default is \code{FALSE} to reduce
the size of the returned object, unless \code{run_model == FALSE}}

\item{family}{\code{character}. Must be either 'nb' (for Negative Binomial), 'tw' (for Tweedie) or 'poisson'}

\item{use_lv}{\code{logical}. If \code{TRUE}, use dynamic factors to estimate series'
latent trends in a reduced dimension format. If \code{FALSE}, estimate independent latent trends for each series}

\item{n_lv}{\code{integer} the number of latent dynamic factors to use if \code{use_lv == TRUE}.
Cannot be \code{>n_series}. Defaults arbitrarily to \code{min(2, floor(n_series / 2))}}

\item{trend_model}{\code{character} specifying the time series dynamics for the latent trend. Options are:
'None' (no latent trend component; i.e. the GAM component is all that contributes to the linear predictor,
and the observation process is the only source of error; similarly to what is estimated by \code{\link[mcgv]{gam}}),
'RW' (random walk with possible drift),
'AR1' (AR1 model with intercept),
'AR2' (AR2 model with intercept) or
'AR3' (AR3 model with intercept) or
'GP' (Gaussian process with squared exponential kernel; currently under development and
only available for estimation in stan)}

\item{drift}{\code{logical} estimate a drift parameter in the latent trend components. Useful if the latent
trend is expected to broadly follow a non-zero slope. Note that if the latent trend is more or less stationary,
the drift parameter can become unidentifiable, especially if an intercept term is included in the GAM linear
predictor (which it is by default when calling \code{\link[mcgv]{jagam}}). Therefore this defaults to \code{FALSE}}

\item{chains}{\code{integer} specifying the number of parallel chains for the model}

\item{burnin}{\code{integer} specifying the number of iterations of the Markov chain to run during
adaptive mode to tune sampling algorithms}

\item{n_samples}{\code{integer} specifying the number of iterations of the Markov chain to run for
sampling the posterior distribution}

\item{thin}{Thinning interval for monitors}

\item{parallel}{\code{logical} specifying whether multiple cores should be used for
generating MCMC simulations in parallel. If \code{TRUE}, the number of cores to use will be
\code{min(c(chains, parallel::detectCores() - 1))}}

\item{phi_prior}{\code{character} specifying (in JAGS or Stan syntax) the prior distribution for the drift terms/intercepts
in the latent trends}

\item{ar_prior}{\code{character} specifying (in JAGS or Stan syntax) the prior distribution for the AR terms
in the latent trends}

\item{r_prior}{\code{character} specifying (in JAGS or Stan syntax) the prior distribution for the Negative Binomial
overdispersion parameters. Note that this prior acts on the inverse of \code{r}, which is convenient
for inducing a complexity-penalising prior model whereby the observation process reduces to a Poisson
as the sampled parameter approaches \code{0}. Ignored if family is Poisson or Tweedie}

\item{twdis_prior}{\code{character} specifying (in JAGS syntax) the prior distribution for the Tweedie
overdispersion parameters. Ignored if family is Poisson or Negative Binomial}

\item{sigma_prior}{\code{character} specifying (in JAGS or Stan syntax) the prior distributions for the independent Gaussian
variances used for the latent trends (ignored if \code{use_lv == TRUE})}

\item{lambda_prior}{\code{character} specifying (in JAGS or Stan syntax) the prior distribution for smoothing
parameters (Default is exponential(0.05))}

\item{rho_gp_prior}{\code{character} specifying (in Stan syntax) the prior distributions for the latent Gaussian
Process length scale parameters}

\item{alpha_gp_prior}{\code{character} specifying (in Stan syntax) the prior distributions for the latent Gaussian
Process marginal deviation parameters}

\item{upper_bounds}{Optional \code{vector} of \code{integer} values specifying upper limits for each series. If supplied,
this generates a modified likelihood where values above the bound are given a likelihood of zero. Note this modification
is computationally expensive in \code{JAGS} but can lead to better estimates when true bounds exist. Default is to remove
truncation entirely (i.e. there is no upper bound for each series)}

\item{use_stan}{Logical. If \code{TRUE} and if \code{rstan} is installed, the model will be compiled and sampled using
the Hamiltonian Monte Carlo with a call to \code{\link[cmdstanr]{cmdstan_model}} or, if \code{cmdstanr} is not available,
a call to \code{\link[rstan]{stan}}. Note that this functionality is still in development and
not all options that are available in \code{JAGS} can be used, including: no option for a Tweedie family and no option for
dynamic factor trends. However, as \code{rstan} can estimate Hilbert base approximate gaussian processes, which
are much more computationally tractable than full GPs for time series with \verb{>100} observations, estimation
in \code{rstan} can support latent GP trends while estimation in \code{JAGS} cannot}

\item{max_treedepth}{positive integer placing a cap on the number of simulation steps evaluated during each iteration when
\code{use_stan == TRUE}. Default is \code{12}. Increasing this value can sometimes help with exploration of complex
posterior geometries, but it is rarely fruitful to go above a \code{max_treedepth} of \code{14}}

\item{adapt_delta}{positive numeric between \code{0} and \code{1} defining the target average proposal acceptance probability
during Stan's adaptation period, if \code{use_stan == TRUE}. Default is \code{0.85}. In general you should not need to change adapt_delta
unless you see a warning message about divergent transitions, in which case you can increase adapt_delta from the default
to a value closer to \code{1} (e.g. from \code{0.95} to \code{0.99}, or from \code{0.99} to \code{0.999}, etc).
The step size used by the numerical integrator is a function of \code{adapt_delta} in that increasing
\code{adapt_delta} will result in a smaller step size and fewer divergences. Increasing \code{adapt_delta} will
typically result in a slower sampler, but it will always lead to a more robust sampler.}

\item{jags_path}{Optional character vector specifying the path to the location of the \code{JAGS} executable (.exe) to use
for modelling if \code{use_stan == FALSE}. If missing, the path will be recovered from a call to \code{\link[runjags]{findjags}}}
}
\value{
A \code{list} object of class \code{mvgam} containing model output, the text representation of the model file,
the mgcv model output (for easily generating simulations at
unsampled covariate values), Dunn-Smyth residuals for each series and key information needed
for other functions in the package
}
\description{
This function estimates the posterior distribution for Generalised Additive Models (GAMs) that can include
smooth spline functions, specified in the GAM formula, as well as latent temporal processes, specified by trend_model.
There are currently two options for specifying the structures of the trends (either as latent
dynamic factors to capture trend dependencies among series in a reduced dimension format, or as independent trends)
}
\details{
Dynamic GAMs are useful when we wish to predict future values from time series that show temporal dependence
but we do not want to rely on extrapolating from a smooth term (which can sometimes lead to unpredictable and unrealistic behaviours).
In addition, smooths can often try to wiggle excessively to capture any autocorrelation that is present in a time series,
which exacerbates the problem of forecasting ahead. As GAMs are very naturally viewed through a Bayesian lens, and we often
must model time series that show complex distributional features and missing data, parameters for \code{mvgam} models are estimated
in a Bayesian framework using Markov Chain Monte Carlo.
\cr
\cr
\emph{Priors}: A \code{\link[mcgv]{jagam}} model file is generated from \code{formula} and modified to include any latent
temporal processes. Prior distributions for most important model parameters can be altered by the user to inspect model
sensitivities to given priors. Note that latent trends are estimated on the log scale so choose tau, AR and phi priors
accordingly. However more control over the model specification can be accomplished by first using \code{mvgam} as a
baseline, then editing the returned model accordingly. The model file can be edited and run outside
of \code{mvgam} by setting \code{run_model = FALSE} and this is encouraged for complex modelling tasks. Note, no priors are
formally checked to ensure they are in the right syntax for the respective probabilistic modelling framework, so it is
up to the user to ensure these are correct (i.e. use \code{dnorm} for normal densities in \code{JAGS}, with the mean and precision
parameterisation; but use \code{normal} for normal densities in \code{Stan}, with the mean and standard deviation parameterisation)
\cr
\cr
\emph{Random effects}: For any smooth terms using the random effect basis (\code{\link[mcgv]{smooth.construct.re.smooth.spec}}),
a non-centred parameterisation is automatically employed to avoid degeneracies that are common in hierarchical models.
Note however that centred versions may perform better for series that are particularly informative, so as with any
foray into Bayesian modelling, it is worth building an understanding of the model's assumptions and limitations by following a
principled workflow.
\cr
\cr
\emph{Overdispersion parameters}: When more than one series is included in \code{data_train} and an overdispersed
exponential family is used, by default the overdispersion parameters (\code{r} for Poisson, \code{twdis} for Tweedie) are
estimated independently for each series. Note that for Tweedie
models, estimating the power parameter \code{p} alongside the overdispersion parameter
\code{twdis} and the smooth coefficients is very challenging for noisy data, introducing some difficult posterior geometries.
The \code{p} parameter is therefore fixed at \code{1.5} (i.e. a so-called Geometric Poisson model).
\cr
\cr
\emph{Factor regularisation}: When using a dynamic factor model for the trends with \code{JAGS} factor precisions are given
regularized penalty priors to theoretically allow some factors to be dropped from the model by squeezing increasing
factors' variances to zero. This is done to help protect against selecting too many latent factors than are needed to
capture dependencies in the data, so it can often be advantageous to set \code{n_lv} to a slightly larger number. However
larger numbers of factors do come with additional computational costs so these should be balanced as well. When using
\code{Stan}, all factors are parameterised with \code{sd = 0.1}
\cr
\cr
\emph{Residuals}: For each series, randomized quantile (i.e. Dunn-Smyth) residuals are calculated for inspecting model diagnostics
If the fitted model is appropriate then Dunn-Smyth residuals will be standard normal in distribution and no
autocorrelation will be evident. When a particular observation is missing, the residual is calculated by comparing independent
draws from the model's posterior distribution
\cr
\cr
\emph{Using Stan}: A useful feature of \code{mvgam} is the ability to use Hamiltonian Monte Carlo for parameter estimation
via the software \code{Stan} (using either the \code{cmdstanr} or \code{rstan} interface). Note that the \code{rstan} library is
currently required for this option to work, even if using \code{cmdstanr} as the backend. This is because \code{rstan}'s functions
are needed to arrange the posterior samples into the correct format for all of \code{mvgam}'s other functions to work.
Also note that currently there is no support for
fitting \code{Tweedie} responses in \code{Stan}.
However there are great advantages when using \code{Stan}, which includes the option to estimate smooth latent trends
via \href{https://arxiv.org/abs/2004.11408}{Hilbert space approximate Gaussian Processes}. This often makes sense for
ecological series, which we expect to change smoothly. In \code{mvgam}, latent squared exponential GP trends are approximated using
by default \code{40} basis functions, which saves computational costs compared to fitting full GPs while adequately estimating
GP \code{alpha} and \code{rho} parameters
}
\examples{
\donttest{
# Simulate a collection of three time series that have shared seasonal dynamics
dat <- sim_mvgam(T = 80, n_series = 3, prop_missing = 0.1,
                trend_rel = 0.6)

# Plot key summary statistics for a single series
plot_mvgam_series(data_train = dat$data_train, series = 1)

# Plot all series together
plot_mvgam_series(data_train = dat$data_train, series = 'all')

# Formulate a model using Stan where series share a cyclic smooth for
# seasonality and each series has an independent random walk temporal process;
# Set run_model = FALSE to inspect the returned objects
mod1 <- mvgam(formula = y ~ s(season, bs = 'cc'),
             data_train = dat$data_train,
             trend_model = 'RW',
             family = 'poisson',
             use_stan = TRUE,
             run_model = FALSE)

# View the model code in Stan language
mod1$model_file

# Inspect the data objects needed to condition the model
str(mod1$model_data)

# Inspect the initial value function used to initialise the MCMC chains
mod1$inits

# The following code can be used to run the model outside of mvgam; first using rstan
model_data <- mod1$model_data
library(rstan)
fit <- stan(model_code = mod1$model_file,
           data = model_data,
           init = mod1$inits)

# Now using cmdstanr
library(cmdstanr)
model_data <- mod1$model_data
cmd_mod <- cmdstan_model(write_stan_file(mod1$model_file),
                        stanc_options = list('canonicalize=deprecations,braces,parentheses'))
cmd_mod$print()
fit <- cmd_mod$sample(data = model_data,
                     chains = 4,
                     parallel_chains = 4,
                     refresh = 500,
                     init = mod1$inits)

# Now fit the model using mvgam with the Stan backend
mod1 <- mvgam(formula = y ~ s(season, bs = 'cc'),
              data_train = dat$data_train,
              trend_model = 'RW',
              family = 'poisson',
              use_stan = TRUE)

# Extract the model summary
summary(mod1)

# Plot the estimated historical trend and forecast for one series
plot(mod1, type = 'trend', series = 1)
plot(mod1, type = 'forecast', series = 1)

# Compute the forecast using covariate information in data_test
plot(object = mod1, type = 'trend', data_test = dat$data_test,
     series = 1)
plot(object = mod1, type = 'forecast', data_test = dat$data_test,
     series = 1)

# Plot the estimated seasonal smooth function
plot(mod1, type = 'smooths')

# Plot estimated first derivatives of the smooth
plot(mod1, type = 'smooths', derivatives = TRUE)

# Plot partial residuals of the smooth
plot(mod1, type = 'smooths', residuals = TRUE)

# Plot posterior realisations for the smooth
plot(mod1, type = 'smooths', realisations = TRUE)
}
}
\seealso{
\code{\link[mcgv]{jagam}}, \code{\link[mcgv]{gam}}
}
\author{
Nicholas J Clark
}
