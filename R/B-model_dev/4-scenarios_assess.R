## 4. Epidemic Model Scenarios Assessment
##
## Interactively explore the output of the simulation. Works with both local and
## HPC results (change `hpc_context` and download the merged_tibbles/ files from
## the HPC first).
##
## Change the scenario name below to inspect different scenarios.

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Setup ------------------------------------------------------------------------
library(EpiModelHIV)
library(dplyr)

source("R/shared_variables.R", local = TRUE)
source("R/B-model_dev/z-context.R", local = TRUE)

# Process ----------------------------------------------------------------------

# Load the results of a single scenario
d_sim <- readRDS(fs::path(
  scenarios_dir, "merged_tibbles",
  "df__pep_75.rds"
))

glimpse(d_sim)
head(d_sim)

d_sim <- d_sim |>
  mutate_calibration_targets() |>
  as.epi.data.frame() # ensure the data.frame can be used with `plot`

plot(
  d_sim,
  y = paste0("cc.dx.", c("B", "H", "W")),
  main = "Proportion of Diagnosed (Black)"
)

# ------------------------------------------------------------------------------
# Scenario Comparison Summary
# ------------------------------------------------------------------------------

library(purrr)
library(tibble)

# Load all scenarios
baseline <- readRDS(fs::path(
  scenarios_dir, "merged_tibbles",
  "df__baseline.rds"
))

pep_25 <- readRDS(fs::path(
  scenarios_dir, "merged_tibbles",
  "df__pep_25.rds"
))

pep_50 <- readRDS(fs::path(
  scenarios_dir, "merged_tibbles",
  "df__pep_50.rds"
))

pep_75 <- readRDS(fs::path(
  scenarios_dir, "merged_tibbles",
  "df__pep_75.rds"
))

# Function to summarize final timestep
get_final_summary <- function(df, scenario_name) {

  df %>%
    filter(time >= max(time) - 12) %>%   # final year
    summarise(
      mean_hiv = mean(hiv.inf),
      sd_hiv = sd(hiv.inf),
      mean_incid = mean(hiv.incid)
    ) %>%
    mutate(scenario = scenario_name)
}

# Create comparison table
comparison_table <- bind_rows(
  get_final_summary(baseline, "Baseline"),
  get_final_summary(pep_25, "PEP 25%"),
  get_final_summary(pep_50, "PEP 50%"),
  get_final_summary(pep_75, "PEP 75%")
)

# Print results
print(comparison_table)
