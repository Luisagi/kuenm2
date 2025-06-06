% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/predict_selected.R
\name{predict_selected}
\alias{predict_selected}
\title{Predict selected models for a single scenario}
\usage{
predict_selected(models, raster_variables, mask = NULL, write_files = FALSE,
                 write_replicates = FALSE, out_dir = NULL,
                 consensus_per_model = TRUE, consensus_general = TRUE,
                 consensus = c("median", "range", "mean", "stdev"),
                 clamping = FALSE, var_to_clamp = NULL, type = "cloglog",
                 overwrite = FALSE, progress_bar = TRUE)
}
\arguments{
\item{models}{an object of class \code{fitted_models} returned by the
\code{\link{fit_selected}}() function.}

\item{raster_variables}{a SpatRaster or data.frame of predictor variables.
The names of these variables must match those used to calibrate the models or
those used to run PCA if \code{do_pca = TRUE} in the \code{\link{prepare_data}}()
function.}

\item{mask}{(SpatRaster, SpatVector, or SpatExtent) spatial object used to
mask the variables before predict. Default is NULL.}

\item{write_files}{(logical) whether to save the predictions (SpatRasters)
to disk. Default is FALSE.}

\item{write_replicates}{(logical) whether to save the predictions for each
replicate to disk. Only applicable if \code{write_files} is TRUE. Default is
FALSE.}

\item{out_dir}{(character) directory path where predictions will be saved.
Only relevant if \code{write_files = TRUE}.}

\item{consensus_per_model}{(logical) whether to compute consensus (mean,
median, etc.) for each model across its replicates. Default is TRUE.}

\item{consensus_general}{(logical) whether to compute a general consensus
across all models. Default is TRUE.}

\item{consensus}{(character) vector specifying the types of consensus to
calculate across replicates and models. Available options are \code{"median"},
\code{"range"}, \code{"mean"}, and \code{"stdev"} (standard deviation). Default is
\code{c("median", "range", "mean", "stdev")}.}

\item{clamping}{(logical) whether to restrict variable values to the range
of the calibration data to avoid extrapolation. Default is FALSE (free
extrapolation).}

\item{var_to_clamp}{(character) vector specifying which variables to clamp.
Only applicable if \code{clamping = TRUE}. Default is \code{NULL}, meaning all
variables will be clamped.}

\item{type}{(character) the format of prediction values. For \code{maxnet} models,
available options are \code{"raw"}, \code{"cumulative"}, \code{"logistic"}, and \code{"cloglog"},
with the default being \code{"cloglog"} for maxnet and \code{"response"} for glm.}

\item{overwrite}{(logical) whether to overwrite SpatRasters if they already
exist. Only applicable if \code{write_files = TRUE}. Default is FALSE.}

\item{progress_bar}{(logical) whether to display a progress bar during
processing. Default is TRUE.}
}
\value{
A list containing SpatRaster predictions for each replicate, along
with the consensus results for each model and the overall general consensus.
}
\description{
This function predicts selected models for a single set of new data
using either \code{maxnet} or \code{glm} It provides options to save the
output and compute consensus results (mean, median, etc.) across
replicates and models.
}
\examples{
# Import variables to predict on
var <- terra::rast(system.file("extdata", "Current_variables.tif",
                               package = "kuenm2"))

# Example with maxnet
# Import example of fitted_models (output of fit_selected())
data("fitted_model_maxnet", package = "kuenm2")

# Predict to single scenario
p <- predict_selected(models = fitted_model_maxnet, raster_variables = var)

# Example with GLMs
# Import example of fitted_models (output of fit_selected())
data("fitted_model_glm", package = "kuenm2")

# Predict to single scenario
p_glm <- predict_selected(models = fitted_model_glm, raster_variables = var)

# Plot predictions
terra::plot(c(p$General_consensus$median, p_glm$General_consensus$median),
            col = rev(terrain.colors(240)), main = c("MAXNET", "GLM"),
            zlim = c(0, 1))
}
