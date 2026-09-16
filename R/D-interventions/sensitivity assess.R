## 6. PEP Sensitivity Analysis Assessment
##
## Assess sensitivity of HIV incidence results to the assumed
## PEP efficacy parameter.
##
## Sensitivity values:
##   PEP efficacy: 60%, 80%, 100%
##   PEP coverage: 25%, 50%, 75%
##
## Outcome:
##   Mean weekly HIV incidence during the final simulation year
##   and percent reduction relative to the no-PEP baseline.
##
## This script can be run directly after restarting R.
## It does NOT rerun any simulations.

# Setup ------------------------------------------------------------------------

library(dplyr)
library(purrr)
library(stringr)
library(tibble)

# Project settings
source("R/shared_variables.R", local = TRUE)
source("R/D-interventions/z-context.R", local = TRUE)

# Sensitivity simulation directory
sensitivity_dir <- fs::path(
  run_dir,
  "sensitivity"
)

# Directory containing merged sensitivity simulations
sens_path <- fs::path(
  sensitivity_dir,
  "merged_tibbles"
)

# Confirm directories exist
stopifnot(
  fs::dir_exists(sensitivity_dir)
)

stopifnot(
  fs::dir_exists(sens_path)
)

cat("\nSensitivity directory:", sensitivity_dir, "\n")
cat("Merged results directory:", sens_path, "\n\n")


# Locate sensitivity results ---------------------------------------------------

sens_files <- fs::dir_ls(
  sens_path,
  regexp = "\\.rds$"
)

cat("Merged sensitivity files found:", length(sens_files), "\n\n")

print(sens_files)

# We expect:
#   1 baseline
#   3 efficacy levels x 3 coverage levels
#   = 10 scenarios total

stopifnot(
  length(sens_files) == 10
)


# Check expected scenarios -----------------------------------------------------

expected_scenarios <- c(
  "baseline",
  "pep25_eff60",
  "pep50_eff60",
  "pep75_eff60",
  "pep25_eff80",
  "pep50_eff80",
  "pep75_eff80",
  "pep25_eff100",
  "pep50_eff100",
  "pep75_eff100"
)

found_scenarios <- fs::path_file(sens_files) |>
  str_remove("^df__") |>
  str_remove("\\.rds$")

stopifnot(
  all(expected_scenarios %in% found_scenarios)
)

cat("\nAll expected sensitivity scenarios found.\n\n")


# Assessment function ----------------------------------------------------------

summarize_sensitivity <- function(file) {

  # Read merged simulation
  d <- readRDS(file)

  # Extract scenario name from filename
  scenario <- fs::path_file(file) |>
    str_remove("^df__") |>
    str_remove("\\.rds$")

  # Identify final simulation year
  final_year_start <- max(
    d$time,
    na.rm = TRUE
  ) - year_steps + 1

  # Retain final simulation year only
  d_final <- d |>
    filter(
      time >= final_year_start
    )

  # Summarize incidence
  tibble(
    scenario = scenario,

    mean_endpoint_incidence =
      mean(
        d_final$hiv.incid,
        na.rm = TRUE
      ),

    sd_endpoint_incidence =
      sd(
        d_final$hiv.incid,
        na.rm = TRUE
      )
  )
}


# Process all scenarios --------------------------------------------------------

sensitivity_results <- map_dfr(
  sens_files,
  summarize_sensitivity
)

cat("\nRaw sensitivity results:\n\n")

print(sensitivity_results)


# Identify baseline ------------------------------------------------------------

baseline_incidence <- sensitivity_results |>
  filter(
    scenario == "baseline"
  ) |>
  pull(
    mean_endpoint_incidence
  )

stopifnot(
  length(baseline_incidence) == 1
)

cat(
  "\nBaseline mean weekly HIV incidence:",
  round(baseline_incidence, 3),
  "\n\n"
)


# Create final sensitivity assessment table -----------------------------------

sensitivity_table <- sensitivity_results |>
  mutate(

    # Extract PEP coverage from scenario name
    pep_coverage = case_when(
      scenario == "baseline" ~ 0,
      str_detect(scenario, "pep25") ~ 25,
      str_detect(scenario, "pep50") ~ 50,
      str_detect(scenario, "pep75") ~ 75,
      TRUE ~ NA_real_
    ),

    # Extract PEP efficacy from scenario name
    pep_efficacy = case_when(
      scenario == "baseline" ~ NA_real_,
      str_detect(scenario, "eff60") ~ 60,
      str_detect(scenario, "eff80") ~ 80,
      str_detect(scenario, "eff100") ~ 100,
      TRUE ~ NA_real_
    ),

    # Percentage reduction in mean weekly HIV incidence
    # relative to the no-PEP baseline
    incidence_reduction =
      100 * (
        baseline_incidence -
          mean_endpoint_incidence
      ) /
      baseline_incidence
  ) |>

  select(
    scenario,
    pep_efficacy,
    pep_coverage,
    mean_endpoint_incidence,
    sd_endpoint_incidence,
    incidence_reduction
  ) |>

  arrange(
    is.na(pep_efficacy),
    pep_efficacy,
    pep_coverage
  )


# Rounded thesis-ready table ---------------------------------------------------

sensitivity_table_final <- sensitivity_table |>
  mutate(
    mean_endpoint_incidence =
      round(mean_endpoint_incidence, 2),

    sd_endpoint_incidence =
      round(sd_endpoint_incidence, 2),

    incidence_reduction =
      round(incidence_reduction, 1)
  )


# Print final table ------------------------------------------------------------

cat(
  "\n",
  "============================================================\n",
  "PEP SENSITIVITY ANALYSIS\n",
  "Final-year mean weekly HIV incidence\n",
  "============================================================\n\n",
  sep = ""
)

print(
  sensitivity_table_final,
  n = Inf
)


# Optional: thesis table without internal scenario names -----------------------

thesis_sensitivity_table <- sensitivity_table_final |>
  transmute(
    `PEP Efficacy (%)` = pep_efficacy,
    `PEP Coverage (%)` = pep_coverage,
    `Mean Weekly HIV Incidence` = mean_endpoint_incidence,
    `SD` = sd_endpoint_incidence,
    `Incidence Reduction (%)` = incidence_reduction
  )

cat(
  "\n",
  "============================================================\n",
  "THESIS-READY TABLE\n",
  "============================================================\n\n",
  sep = ""
)

print(
  thesis_sensitivity_table,
  n = Inf
)


# Save table -------------------------------------------------------------------

write.csv(
  thesis_sensitivity_table,
  fs::path(
    output_dir,
    "pep_sensitivity_analysis.csv"
  ),
  row.names = FALSE,
  na = "Baseline"
)

cat(
  "\nSensitivity assessment complete.\n",
  "Table saved to: ",
  fs::path(
    output_dir,
    "pep_sensitivity_analysis.csv"
  ),
  "\n",
  sep = ""
)
