kuenm2: Detailed Development of Ecological Niche Models
================
Weverton C. F. Trindade, Luis F. Arias-Giraldo, Luis Osorio-Olvera, A.
Townsend Peterson, and Marlon E. Cobos

- [Package description](#package-description)
- [Installing the package](#installing-the-package)
- [Workflow in kuenm2](#workflow-in-kuenm2)
  - [Pre-modeling steps](#pre-modeling-steps)
  - [Model development](#model-development)
  - [Post-modeling analysis](#post-modeling-analysis)
- [Checking the vignettes](#checking-the-vignettes)

<hr>

<br>

## Package description

**kuenm2** is an new version of **kuenm** [Cobos et
al. 2019](https://peerj.com/articles/6281/), an R package designed to
make the process of ecological niche modeling (ENM) easier, faster, and
more reproducible, and at the same time more robust. The aim of this
package is to facilitate crucial steps in the ENM process: data
preparation, model calibration, selected model exploration, model
projections, and analyses of uncertainty and variability.

This new version of the package reduces the dependency on a strictly
organized working directory (now required only if projections to
multiple scenarios are needed). Instead, kuenm2 functions generate
specific R objects that store all the necessary information for
subsequent steps. kuenm2 fits maximum entropy (Maxnet) models or
logistic generalized linear models (GLMs). Maxnet models are created as
described in [Phillips et
al. (2017)](http://doi.wiley.com/10.1111/ecog.03049), and GLMs are
constructed as in [Cobos and Peterson
(2023)](https://doi.org/10.1371/journal.pone.0276951). The ENM workflow
requires at minimum a `data.frame` containing occurrence record
coordinates (longitude and latitude) and a `SpatRaster` object with
predictor variables. Users could also use a `data.frame` containing a
column indicating presence and background records (0/1), and other
columns with predictor variable values.

<br>

## Installing the package

Note: Internet connection is required to install the package.

To install the latest release of kuenm2 use the following line of code:

``` r
# Installing from CRAN 
#install.packages("kuenm2")  # in progress
```

<br>

The development version of kuenm2 can be installed using the code below.

``` r
# Installing and loading packages
if(!require(remotes)){
  install.packages("remotes")
}

# To install the package use
remotes::install_github("marlonecobos/kuenm2")

# To install the package and its vignettes use (if needed use: force = TRUE)  
remotes::install_github("marlonecobos/kuenm2", build_vignettes = TRUE)
```

<br>

*Having problems?*

If you have any problems during installation of the development version
from GitHub, restart R session, close other RStudio sessions you may
have open, and try again. If during the installation you are asked to
update packages, do so if you don’t need a specific version of one or
more of the packages to be installed. If any of the packages gives an
error when updating, please install it alone using `install.packages()`,
then try installing kuenm2 again.

<br>

To load the package use:

``` r
# Load kuenm2
library(kuenm2)
```

<br>

## Workflow in kuenm2

The kuenm2 package facilitates the following steps in the ENM process:
basic data cleaning, data preparation, model calibration, model
exploration, model projections, projection comparisons, and exploration
of variability and uncertainty. The figure below shows a schematic view
of how the package works. A brief description of the steps that can be
performed with the package is presented below. For a complete
description and demonstration of the steps, see the package vignettes
listed in the section [Checking the vignettes](#checking-the-vignettes).

<div class="figure" style="text-align: center">

<img src="man/figures/kuenm2_map_gs.png" alt="Figure 1. Overview of the kuenm2 workflow for ecological niche modeling." width="461" />
<p class="caption">

Figure 1. Overview of the kuenm2 workflow for ecological niche modeling.
</p>

</div>

### Pre-modeling steps

#### Basic data cleaning

kuenm2 automates essential pre-processing steps for ecological niche
modeling. Data cleaning tools help sort columns, remove missing values
and duplicates (including duplicates within raster cells), exclude
coordinates at (0,0), filter based on coordinate decimal precision, and
adjust occurrences that fall just outside valid raster boundaries.

#### Data preparation

For data preparation, users can input raw occurrence records and raster
layers or provide a pre-processed data frame. Two primary functions,
`prepare_data()` and `prepare_user_data()`, guide users through the
process of choosing modeling algorithms, defining parameter sets (e.g.,
feature classes, regularization multipliers, and predictor variables),
and selecting data partitioning strategies. Additional tools allow users
to visualize environmental conditions in the calibration data and assess
similarities among training and testing partitions, an exclusive feature
of kuenm2 among ENM tools.

### Model development

#### Model calibration

Model calibration in kuenm2 is computationally intensive, involving
training and testing of candidate models using various partitioning
strategies such as k-fold cross-validation, subsampling, and
bootstrapping. Custom partitions generated using external tools (e.g.,
block or checkerboard methods) can also be imported. Models are
evaluated using multiple performance criteria that emphasize sensitivity
due to the frequent lack of true absence data. These criteria include:
bimodality in response curves, partial ROC for statistical significance,
omission rates for predictive performance, and Akaike Information
Criterion (AIC) for model complexity. Model calibration is executed
using the `calibration()` function.

To support a deeper understanding of the calibration process, a step to
explore further extrapolation risks in the testing partitions can be
performed in kuenm2. Tools in the package help to produce visualizations
of response curves from training data overlapped with environmental
conditions at testing sites for selected models. This another option
exclusive to kuenm2.

#### Model explorations

Once best models are selected, they must be fitted using
`fit_selected()` to analyze their characteristics and behavior. Fitted
models can be explored to assess variable importance and examine
response curves. This offers insights into predictor influence in models
and ecological interpretation.

If an independent set of records (not included for model calibration) is
available, it can be used to re-evaluate the predictive performance of
selected models. Partial ROC and omission rates are calculated for these
new records to measure model performance, but extrapolation risks also
are assessed for these points using the MOP metric (exclusive to
kuenm2). Results from this evaluation can help further filter the
selected models or inform the decision to incorporate the independent
records into the calibration dataset.

#### Model projections

Fitted models can be projected to new environmental scenarios, including
larger geographic areas or different temporal conditions (e.g., past or
future climates). For single scenario projections, use
`predict_selected()`; for multiple scenarios, use `project_selected()`.
Before projecting to complex future scenarios (e.g., multiple time
periods, emission pathways, or GCMs), users should first prepare and
organize data using functions in *kuenm2* that facilitate the process
(e.g., `organize_future_worldclim()`).

### Post-modeling analysis

#### Projection comparisons

When projecting to multiple scenarios, kuenm2 provides tools to quantify
and characterize differences using `projection_changes()`. This function
evaluates spatial changes and agreement levels among projections, aiding
the interpretation of temporal or scenario-based shifts in suitability.

#### Variability and uncertainty

To assess the consistency and reliability of model outputs, users can
explore projection variability (`projection_variability()`), which
accounts for differences arising from model replicates, parameter sets,
and climate models. With the MOP metric (`projection_mop()`) users can
evaluate extrapolation risks by identifying novel environmental
conditions in projection areas, offering a spatially explicit
representation of model uncertainty.

<br>

## Checking the vignettes

Users can check kuenm2 vignettes for a full explanation of the package
functionality. If installing the development version form GitHub, make
sure to use the argument `build_vignettes = TRUE`.

Check each of the vignettes with the code below:

``` r
# Guide to basic data cleaning before the ENM process
vignette("basic_data_cleaning")

# Guide to prepare data for the ENM process
vignette("prepare_data")

# Guide to train and evaluate candidate models, and select based on performance
vignette("model_calibration") 

# Guide to explore selected models, variable importance, response curves
vignette("model_exploration")

# Guide to predict models in geographic space (single scenarios)
vignette("model_predictions")

# Guide to project models in geographic space (multiple scenarios)
vignette("model_projections") 

# Guide to explore variability and uncertainty in projections (multiple scenarios)
vignette("variability_and_uncertainty")

# Guide to make projections to multiple scenarios with layers from CHELSA Climate
vignette("projections_chelsa")
```
