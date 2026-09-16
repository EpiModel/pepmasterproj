## 2. Intervention Scenarios Process Tables
##
## Make the tables using the results of the simulations from the
## previous step locally or on the HPC (see `workflow-interventions.R`)

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Setup ------------------------------------------------------------------------
library(dplyr)
library(tidyr)

source("R/shared_variables.R", local = TRUE)
source("R/D-interventions/z-context.R", local = TRUE)

source("R/D-interventions/outcomes.R", local = TRUE)

# Process ----------------------------------------------------------------------

scenarios_tibble_dir <- fs::path(scenarios_dir, "merged_tibbles")
scenarios_info <- EpiModelHPC::get_scenarios_tibble_infos(scenarios_tibble_dir)

# Reference (baseline) scenario — NIA/PIA are computed relative to this.
# Update if your baseline has a different name.
d_ref <- make_d_ref(
  fs::path(
    scenarios_tibble_dir,
    "df__pep_25.rds"
  )
)

d_ls <- future.apply::future_lapply(
  seq_len(nrow(scenarios_info)),
  function(i) process_one_scenario(scenarios_info[i, ], d_ref)
)

d_sc_raw <- dplyr::bind_rows(d_ls)
glimpse(d_sc_raw)

# Create total cumulative HIV infections across race groups
d_summary <- d_sc_raw |>
  mutate(
    cumulative_infections =
      cml_incid_B +
      cml_incid_H +
      cml_incid_W
  ) |>
  group_by(scenario_name) |>
  summarise(
    mean_cumulative_infections = mean(cumulative_infections),
    sd_cumulative_infections   = sd(cumulative_infections),
    .groups = "drop"
  )

# Get baseline mean
baseline_cumulative <- d_summary |>
  filter(scenario_name == "baseline") |>
  pull(mean_cumulative_infections)

# Calculate infections averted relative to baseline
d_summary <- d_summary |>
  mutate(
    mean_infections_averted =
      baseline_cumulative - mean_cumulative_infections,

    percent_infections_averted =
      100 * mean_infections_averted / baseline_cumulative
  )

print(d_summary)

source("R/D-interventions/labels.R", local = TRUE)

format_table(d_sc_raw, var_labels, format_patterns) |>
  write.csv(fs::path(output_dir, "table.csv"), row.names = FALSE)
