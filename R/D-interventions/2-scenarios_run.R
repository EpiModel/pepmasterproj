## 2. Intervention Scenarios Playground
##
## Example interactive epidemic simulation run script with more complex
## parameterization and parameters defined in spreadsheet, with example
## of running model scenarios defined with data-frame approach

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Setup ------------------------------------------------------------------------
library(EpiModelHIV)
library(dplyr)

source("R/shared_variables.R", local = TRUE)
source("R/D-interventions/z-context.R", local = TRUE)

# Process ----------------------------------------------------------------------

# Necessary files
source("R/netsim_settings.R", local = TRUE)

# Control settings
control <- control_msm(
  start               = restart_time,
  nsteps              = intervention_end,
  initialize.FUN      = reinit_msm,
  verbose             = FALSE
)

# Define test scenarios
scenarios_df <- read.csv(fs::path(input_dir, "scenarios.csv"))

glimpse(scenarios_df)
scenarios_list <- EpiModel::create_scenario_list(scenarios_df)

EpiModelHPC::netsim_scenarios(
  path_to_restart, param, init, control,
  scenarios_list = scenarios_list,
  n_rep = 8,
  n_cores = 4,
  output_dir = scenarios_dir
)
fs::dir_ls(scenarios_dir)

# merge the simulations. Keeping one `tibble` per scenario
EpiModelHPC::merge_netsim_scenarios_tibble(
  sim_dir = scenarios_dir,
  output_dir = fs::path(scenarios_dir, "merged_tibbles"),
  steps_to_keep = intervention_end - intervention_start
)

# Convert to data frame
d_path <- fs::dir_ls(fs::path(scenarios_dir, "merged_tibbles"))[[1]]
d_sim <- readRDS(d_path)

glimpse(d_sim)
head(d_sim)

## Clean folder
# fs::dir_delete(sc_test_dir)

# below is the script I actually ran

## 2. Intervention Scenarios Playground
##
## Final PEP intervention scenarios.
## Starts from the Chapter C restart point and compares:
## baseline, 25%, 50%, and 75% PEP coverage.
##
## PEP efficacy remains fixed at 80%.

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

# Confirm baseline PEP settings
print(param$pep.coverage)
print(param$pep.efficacy)

# Expected:
# pep.coverage = 0
# pep.efficacy = 0.8

stopifnot(param$pep.coverage == 0)
stopifnot(param$pep.efficacy == 0.8)

# Confirm restart point exists
stopifnot(file.exists(path_to_restart))

# Control settings -------------------------------------------------------------

control <- control_msm(
  start          = restart_time,
  nsteps         = intervention_end,
  initialize.FUN = reinit_msm,
  verbose        = FALSE
)

# IMPORTANT:
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

cat("\nModified PEP transmission module successfully loaded.\n")
cat("Restart time:", restart_time, "\n")
cat("Intervention start:", intervention_start, "\n")
cat("Intervention end:", intervention_end, "\n")
cat("PEP efficacy:", param$pep.efficacy, "\n\n")


# Intervention scenarios -------------------------------------------------------

# IMPORTANT:
# read.csv() returns a base data.frame, but create_scenario_list()
# requires the tibble structure here.
scenarios_df <- read.csv(
  fs::path(input_dir, "scenarios.csv"),
  check.names = FALSE
) |>
  tibble::as_tibble()

print(scenarios_df)
glimpse(scenarios_df)

# Check scenario definitions
stopifnot(
  all(scenarios_df$.at == intervention_start)
)

stopifnot(
  all(
    scenarios_df$pep.coverage ==
      c(0, 0.25, 0.50, 0.75)
  )
)

stopifnot(
  scenarios_df$.scenario.id ==
    c("baseline", "pep_25", "pep_50", "pep_75")
)

# Convert scenario table for EpiModel
scenarios_list <- EpiModel::create_scenario_list(
  scenarios_df
)

cat("\nScenario list successfully created.\n")


# Run intervention simulations -------------------------------------------------

# Each scenario is independently replicated 100 times.
#
# baseline = 0% PEP coverage
# pep_25   = 25% PEP coverage
# pep_50   = 50% PEP coverage
# pep_75   = 75% PEP coverage
#
# PEP efficacy remains fixed at 80% for all scenarios.

EpiModelHPC::netsim_scenarios(
  path_to_restart,
  param,
  init,
  control,
  scenarios_list = scenarios_list,
  n_rep = 100,
  n_cores = 8,
  output_dir = scenarios_dir
)

# Inspect generated batch files
fs::dir_ls(scenarios_dir)


# Merge simulations ------------------------------------------------------------

# Keep the intervention period for analysis.
EpiModelHPC::merge_netsim_scenarios_tibble(
  sim_dir = scenarios_dir,
  output_dir = fs::path(
    scenarios_dir,
    "merged_tibbles"
  ),
  steps_to_keep = intervention_end - intervention_start
)


# Verify merged results ---------------------------------------------------------

merged_files <- fs::dir_ls(
  fs::path(
    scenarios_dir,
    "merged_tibbles"
  )
)

print(merged_files)

# Load one result simply to verify output structure
d_sim <- readRDS(merged_files[[1]])

glimpse(d_sim)
head(d_sim)

cat("\nFinal PEP intervention simulations completed successfully.\n")
