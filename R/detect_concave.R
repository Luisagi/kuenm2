#' Detect concave curves in GLM and GLMNET models
#'
#' @description
#' Identifies the presence of concave response curves within the calibration
#' range of GLM and GLMNET models.
#'
#' @usage detect_concave(model, calib_data, extrapolation_factor = 0.1,
#'                      var_limits = NULL, averages_from, plot = FALSE,
#'                      mfrow = NULL, legend = FALSE)
#'
#' @param model an object of class `glmnet_mx` or `glm`.
#' @param calib_data data.frame or matrix of data used for model calibration.
#' @param extrapolation_factor (numeric) a multiplier used to calculate the
#' extrapolation range. Larger values allow broader extrapolation beyond the
#' observed data range. Default is 0.1.
#' @param var_limits (list) A named list specifying the lower and/or upper limits
#' for some variables. The first value represents the lower limit, and the
#' second value represents the upper limit. Default is \code{NULL}, meaning no
#' specific limits are applied, and the range will be calculated using the
#' \code{extrapolation_factor}. See details.
#' @param averages_from (character) specifies how the averages or modes of the
#' variables are calculated. Available options are "pr" (to calculate averages
#' from the presence localities) or "pr_bg" (to use the combined set of presence
#' and background localities). Default is "pr". See details.
#' @param plot (logical) whether to plot the response curve for the variables.
#' Default is FALSE.
#' @param mfrow (numeric) a vector of the form c(number of rows, number of columns)
#' specifying the layout of plots. Default is c(1, 1), meaning one plot per window.
#' @param legend (logical) whether to include a legend in the plot. The legend
#' indicates whether the response curve is convex, concave outside the range
#' limits, or concave within the range limits. Default is FALSE.
#'
#' @details
#' Concave curves are identified by analyzing the beta coefficients of quadratic
#' terms within the variable's range. The range for extrapolation is calculated
#' as the difference between the variable's maximum and minimum values in the
#' model, multiplied by the extrapolation factor. A concave curve is detected
#' when the beta coefficient is positive, and the vertex — where the curve
#' changes direction — lies between the lower and upper limits of the variable.
#'
#' Users can specify the lower and upper limits for certain variables using
#' \code{var_limits}. For example, if \code{var_limits = list("bio12" = c(0, NA),
#' "bio15" = c(0, 100))}, the lower limit for \code{bio12} will be 0, and the
#' upper limit will be calculated using the extrapolation factor. Similarly,
#' the lower and upper limits for \code{bio15} will be 0 and 100, respectively.
#'
#' For calculating the vertex position, a response curve for a given variable is
#' generated with all other variables set to their mean values (or mode for
#' categorical variables). These values are calculated either from the presence
#' localities (if \code{averages_from = "pr"}) or from the combined set of
#' presence and background localities (if \code{averages_from = "pr_bg"}).
#'
#'
#' @return A list with the following elements for each variable:
#'  - is_concave (logical): indicates whether the response curve for the variable
#'    is concave within the limit range. This occurs when the quadratic term's
#'    coefficient is positive and the vertex lies between x_min and x_max,
#'  - vertex (numeric): the vertex of the parabola, representing the point where the curve
#'    changes direction.
#'  - b2 (numeric): the coefficient of the quadratic term for the variable.
#'    Positive values indicate a concave curve.
#'  - x_min and x_max (numeric): the range limits to identify concave curves,
#'    calculated as the observed data range multiplied by the extrapolation
#'    factor.
#'  - real_x_min and real_x_max (numeric) the actual range of the data,
#'    excluding the extrapolation factor.
#'
#' @importFrom stats predict coef
#' @importFrom graphics abline points text mtext
#'
#' @export
#'
#' @examples
#' # Import example of a fitted_model (output of fit_selected()) that have
#' # concave curves
#' data("fitted_model_concave", package = "kuenm2")
#'
#' #Response curves
#' detect_concave(model = fitted_model_concave$Models$Model_798$Full_model,
#'                calib_data = fitted_model_concave$calibration_data,
#'                extrapolation_factor = 0.2,
#'                limit_is_zero = c("sand", "clay"),
#'                plot = TRUE, mfrow = c(2, 3), legend = TRUE)
#'
detect_concave <- function(model, calib_data,
                          extrapolation_factor = 0.1,
                          averages_from = "pr",
                          var_limits = NULL, plot = FALSE,
                          mfrow = NULL, legend = FALSE){


  if (!inherits(extrapolation_factor, "numeric")) {
    stop(paste0("Argument extrapolate must be numeric, not ",
                class(extrapolation_factor)))
  }

  if (!averages_from %in% c("pr_bg", "pr")) {
    stop("Argument averages_from must be 'pr_bg' or 'pr'")
  }

  #Get modeltype
  model_type <- if(inherits(model, "glmnet_mx")){
    "glmnet_mx"} else if (inherits(model, "glm")) {
      "glm"}

  #Get coefficients
  if(model_type == "glmnet_mx"){
    coefs <- coef(model)[,200]
  } else {
    coefs <- coef(model)
  }

  #Subset calib_data
  if(averages_from == "pr_bg"){
    calib_data <- calib_data[calib_data$pr_bg == 1, ]
  }

  #Get means of variables from calibration data
  means <- colMeans(calib_data[sapply(calib_data, is.numeric)])[-1]

  #Mode of categorical variables
  cv <- colnames(calib_data)[sapply(calib_data, class) == "factor"]
  if(length(cv) > 0){
    mode_cat <- sapply(cv, function(x){
      as.numeric(names(which.max(table(calib_data[, x]))))
    })
    means <- c(means, mode_cat)
  } else {cv <- NULL}

  #Calculate vertex
  vertex <- calculate_vertex(coefs, means)

  #Variables to limit manually
  if(!is.null(var_limits)){
    v_lim <- names(var_limits)
    #Check if some variable is not correctly assigned
    var_out <- setdiff(v_lim, colnames(calib_data))
    if(length(var_out) > 0)
      stop("Variables specified in 'var_limits' are absent from the model.\n",
           "The available variables for defining limits are: ",
           paste(names(vertex), collapse = "; "))
  }

  #Store information in a list
  var_info <- lapply(names(vertex), function(v){

    #Get extrapolation
    rr <- diff(c(model$varmin[[v]], model$varmax[[v]]))
    extrapolation_factor_i <- rr * extrapolation_factor

    x_min <- model$varmin[[v]] - extrapolation_factor_i
    x_max <- model$varmax[[v]] + extrapolation_factor_i

    #Set manual limits
    if(!is.null(var_limits)){
    if(v %in% v_lim){
      if(!is.na(var_limits[[v]][1]))
        x_min <- var_limits[[v]][1]

      if(!is.na(var_limits[[v]][2]))
        x_max <- var_limits[[v]][2]
    }
    }

    #Beta coefficient
    b2 <- coefs[[paste0("I(", v, "^2)")]]

    #Check if curve is concave
    is_concave <- b2 > 0 &
      vertex[[v]] > x_min &
      vertex[[v]] < x_max

    return(list("is_concave" = is_concave,
             "vertex" = vertex[[v]],
             "b2" = b2,
             "x_min" = x_min,
             "x_max" = x_max,
             "real_x_min" = model$varmin[[v]],
             "real_x_max" = model$varmax[[v]]))
    })

  names(var_info) <- names(vertex)

  #If plot...
  if(plot){

    #Set grid of the plot
    if(!is.null(mfrow)){
      par(mfrow = mfrow) # Create a plotting matrix
    } else {par(mfrow = c(1,1))}

    for(i in names(var_info)){
      r <- response(model = model, data = calib_data, variable = i,
                    type = "cloglog", n = 100,
                    new_data = NULL, extrapolate = TRUE,
                    extrapolation_factor = extrapolation_factor,
                    categorical_variables = cv,
                    averages_from = averages_from,
                    l_limit = var_info[[i]]$x_min, u_limit = var_info[[i]]$x_max)
      #Extract info to plot
      variable <- i
      x_values <- r[,1]
      y_values <- r[,2]
      x_min <- var_info[[i]][["x_min"]]
      x_max <- var_info[[i]][["x_max"]]
      beta2 <- var_info[[i]][["b2"]]
      vertex_v <- var_info[[i]][["vertex"]]
      beta0 <- coefs[[1]]
      real_xmin <- model$varmin[[variable]]
      real_xmax <- model$varmax[[variable]]

      plot_curve_direction(model, x_values, y_values, variable, x_min, x_max,
                           beta2, vertex_v, real_xmin, real_xmax, means, legend,
                           model_type)
    }

    #Set mfrow to default again
    if(!is.null(mfrow)){
      par(mfrow = c(1,1))}

  } #End of plot
  return(var_info)
}

# Plot curve
plot_curve_direction <- function(model, x_values, y_values, variable, x_min, x_max,
                                 beta2, vertex_v, real_xmin, real_xmax, means,
                                 legend = legend, model_type) {

  # Plot curve
  plot(x_values, y_values, type = "l", col = "blue",
       xlab = variable, ylab = "Suitability", main = variable)

  # Add vertex to the graph
  #Get variables means
  means_v <- as.data.frame(t(c(means[names(means) != variable],
                               setNames(vertex_v, variable))))
  if(model_type == "glmnet_mx"){
    p_vertex <- predict.glmnet_mx(model, newdata = means_v, type = "cloglog")
  } else {
    p_vertex <- predict.glm(model, newdata = means_v, type = "response")
  }
  points(vertex_v, p_vertex, col = "red", pch = 19)
  text(vertex_v, p_vertex, "vertex", col = "red", pos = 4)  # Add the text "vertex"


  # Add variable range
  abline(v = real_xmin, col = "gray", lty = 2)
  abline(v = real_xmax, col = "gray", lty = 2)

  if(legend){
    result <- if(beta2 < 0) {
      "Convex curve"
    } else if (beta2 > 0 & vertex_v > x_min & vertex_v < x_max) {
      "Concave curve inside the range"
    } else if (beta2 > 0 & (vertex_v < x_min | vertex_v > x_max)){
      "Concave curve outside the range"}

    # legend("topright", legend = result, col = "black", lty = 1, cex = 0.8,
    #        bty = "n")

    #Get color of subtitle
    color_sub <- if(beta2 < 0) {
      "forestgreen"
    } else if (beta2 > 0 & vertex_v > x_min & vertex_v < x_max) {
      "red"
    } else if (beta2 > 0 & (vertex_v < x_min | vertex_v > x_max)){
      "orange"}

    mtext(result, side = 3, line = 0.5, cex = 0.8, col = color_sub, font = 2)

  }
}

calculate_vertex <- function(coefs, means) {

  #Get only coefs greater than 0
  coefs <- coefs[coefs != 0]

  #Get only variables with quadratic term
  variables <- grep("\\^2", names(coefs), value = TRUE)

  variables <- gsub("I\\((.*)\\^2\\)", "\\1", variables)

  # Create vector to store vertex
  vertices <- numeric(length(variables))
  names(vertices) <- variables

  # Loop for calculating vertex for each variable
  for (var in variables) {

    # Linear coefficient
    linear_coef <- coefs[var]
    if(is.na(linear_coef)){
      linear_coef <- 0 #Set to 0 if there is not a linear coefficient
    }

    # Coeficiente quadrático da variável
    quadratic_coef <- coefs[paste0("I(", var, "^2)")]

    # Identify interactions between products
    interaction_terms <- grep(paste0("^", var, ":", "|:", var, "$"),
                              names(coefs), value = TRUE)
    interaction_effect <- 0 #Start interation effect in 0

    # Sum interaction effects
    for (term in interaction_terms) {
      # Identify the other variable in the interaction and sum its effect
      other_var <- setdiff(strsplit(term, ":")[[1]], var)
      if (length(other_var) > 0 && other_var %in% names(means)) {
        interaction_effect <- interaction_effect + coefs[term] * means[other_var]
      }
    }

    # Calcular o vértice usando a fórmula
    vertices[var] <- (-linear_coef - interaction_effect) / (2 * quadratic_coef)
  }

  return(vertices)
}

# #Test
# detect_concave(model = fitted_model_glm$Models$Model_2$Full_model,
#                calib_data = fitted_model_glm$calibration_data,
#                extrapolation_factor = 2,
#                plot = T,
#                mfrow = NULL, legend = T)


#
# fm <- data("fitted_models")
#
# data("fitted_model_glmnet", package = "kuenm2")
