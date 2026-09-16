## PEP Efficacy Sensitivity Analysis
##
## Tests whether conclusions about PEP remain consistent when the assumed
## efficacy parameter is varied.
##
## Primary analysis:
##   pep.efficacy = 0.80
##
## Sensitivity values:
##   pep.efficacy = 0.60
##   pep.efficacy = 1.00
##
## PEP coverage:
##   25%, 50%, 75%
##
## Baseline:
##   PEP coverage = 0
##
## All simulations start from the same Chapter C restart point.

# Restart R before running this script (Ctrl+Shift+F10)

# Setup ------------------------------------------------------------------------

library(EpiModelHIV)
library(dplyr)

# Load modified HIV transmission module containing PEP
source(
  "C:/Users/danie/Documents/master's thesis/EpiModelHIV-p/R/mod.hivtrans.R",
  local = TRUE
)

# Save modified function under a separate name
my_hivtrans <- hivtrans_msm

# Give modified function access to EpiModelHIV internal functions/objects
environment(my_hivtrans) <- asNamespace("EpiModelHIV")

# Project settings
source("R/shared_variables.R", local = TRUE)
source("R/D-interventions/z-context.R", local = TRUE)

# Process ----------------------------------------------------------------------

# Load network statistics, model parameters, init object,
# and restart-point path
source("R/netsim_settings.R", local = TRUE)

# Confirm original/default PEP settings
print(param$pep.coverage)
print(param$pep.efficacy)

# Expected:
# pep.coverage = 0
# pep.efficacy = 0.8

stopifnot(param$pep.coverage == 0)
stopifnot(param$pep.efficacy == 0.8)

# Confirm restart point exists
stopifnot(file.exists(path_to_restart))


# Sensitivity output directory -------------------------------------------------

# IMPORTANT:
# Keep sensitivity results separate from the main intervention results.
sensitivity_dir <- fs::path(run_dir, "sensitivity")

# Create directory if it does not already exist
fs::dir_create(sensitivity_dir)


# Control settings -------------------------------------------------------------

control <- control_msm(
  start          = restart_time,
  nsteps         = intervention_end,
  initialize.FUN = reinit_msm,
  verbose        = FALSE
)

# Force simulations to use modified PEP-aware HIV transmission function
control$hivtrans.FUN <- my_hivtrans

# Verify modified module is actually inside control
stopifnot(
  any(
    grepl(
      "pep.coverage",
      deparse(body(control$hivtrans.FUN))
    )
  )
)

stopifnot(
  any(
    grepl(
      "pep.efficacy",
      deparse(body(control$hivtrans.FUN))
    )
  )
)

cat("\nModified PEP transmission module successfully loaded.\n")
cat("Restart time:", restart_time, "\n")
cat("Intervention start:", intervention_start, "\n")
cat("Intervention end:", intervention_end, "\n")
cat("Primary PEP efficacy:", param$pep.efficacy, "\n\n")


# Sensitivity scenarios --------------------------------------------------------

# One baseline plus nine PEP scenarios:
#
#                Coverage
# Efficacy       25%    50%    75%
# --------------------------------
# 60%             X      X      X
# 80%             X      X      X
# 100%            X      X      X
#
# The baseline has PEP coverage = 0.
#
# Efficacy therefore has no effect in the baseline scenario.

sensitivity_df <- tibble::tribble(
  ~.scenario.id,  ~.at,               ~pep.coverage, ~pep.efficacy,

  "baseline",      intervention_start,  0.00,          0.80,

  "pep25_eff60",   intervention_start,  0.25,          0.60,
  "pep50_eff60",   intervention_start,  0.50,          0.60,
  "pep75_eff60",   intervention_start,  0.75,          0.60,

  "pep25_eff80",   intervention_start,  0.25,          0.80,
  "pep50_eff80",   intervention_start,  0.50,          0.80,
  "pep75_eff80",   intervention_start,  0.75,          0.80,

  "pep25_eff100",  intervention_start,  0.25,          1.00,
  "pep50_eff100",  intervention_start,  0.50,          1.00,
  "pep75_eff100",  intervention_start,  0.75,          1.00
)

print(sensitivity_df)
glimpse(sensitivity_df)


# Check scenario definitions ---------------------------------------------------

# All interventions should start at timestep 262
stopifnot(
  all(sensitivity_df$.at == intervention_start)
)

# Check coverage values
stopifnot(
  all(
    sensitivity_df$pep.coverage ==
      c(
        0,
        0.25, 0.50, 0.75,
        0.25, 0.50, 0.75,
        0.25, 0.50, 0.75
      )
  )
)

# Check efficacy values
stopifnot(
  all(
    sensitivity_df$pep.efficacy ==
      c(
        0.80,
        0.60, 0.60, 0.60,
        0.80, 0.80, 0.80,
        1.00, 1.00, 1.00
      )
  )
)


# Convert scenario table for EpiModel -----------------------------------------

sensitivity_list <- EpiModel::create_scenario_list(
  sensitivity_df
)

cat("\nSensitivity scenario list successfully created.\n")


# Run sensitivity simulations --------------------------------------------------

# Each scenario is independently replicated 100 times.
#
# This matches the number of replicates used in the primary intervention
# analysis so uncertainty is comparable across analyses.

EpiModelHPC::netsim_scenarios(
  path_to_restart,
  param,
  init,
  control,
  scenarios_list = sensitivity_list,
  n_rep = 100,
  n_cores = 8,
  output_dir = sensitivity_dir
)


# Inspect generated batch files ------------------------------------------------

fs::dir_ls(sensitivity_dir)


# Merge simulations ------------------------------------------------------------

EpiModelHPC::merge_netsim_scenarios_tibble(
  sim_dir = sensitivity_dir,
  output_dir = fs::path(
    sensitivity_dir,
    "merged_tibbles"
  ),
  steps_to_keep = intervention_end - intervention_start
)


# Verify merged results ---------------------------------------------------------

merged_files <- fs::dir_ls(
  fs::path(
    sensitivity_dir,
    "merged_tibbles"
  )
)

print(merged_files)


# Verify parameters stored in selected raw simulations -------------------------

baseline_check <- readRDS(
  fs::path(
    sensitivity_dir,
    "sim__baseline__1.rds"
  )
)

eff60_check <- readRDS(
  fs::path(
    sensitivity_dir,
    "sim__pep75_eff60__1.rds"
  )
)

eff80_check <- readRDS(
  fs::path(
    sensitivity_dir,
    "sim__pep75_eff80__1.rds"
  )
)

eff100_check <- readRDS(
  fs::path(
    sensitivity_dir,
    "sim__pep75_eff100__1.rds"
  )
)

cat("\nParameter verification:\n")

cat(
  "Baseline: coverage =",
  baseline_check$param$pep.coverage,
  ", efficacy =",
  baseline_check$param$pep.efficacy,
  "\n"
)

cat(
  "75% coverage / 60% efficacy: coverage =",
  eff60_check$param$pep.coverage,
  ", efficacy =",
  eff60_check$param$pep.efficacy,
  "\n"
)

cat(
  "75% coverage / 80% efficacy: coverage =",
  eff80_check$param$pep.coverage,
  ", efficacy =",
  eff80_check$param$pep.efficacy,
  "\n"
)

cat(
  "75% coverage / 100% efficacy: coverage =",
  eff100_check$param$pep.coverage,
  ", efficacy =",
  eff100_check$param$pep.efficacy,
  "\n"
)


# Load one merged result simply to verify output structure ---------------------

d_sim <- readRDS(merged_files[[1]])

glimpse(d_sim)
head(d_sim)

cat("\nPEP efficacy sensitivity analysis completed successfully.\n")
