library(dplyr)

# Load final Module D scenario outputs
baseline <- readRDS(
  fs::path(scenarios_dir, "merged_tibbles", "df__baseline.rds")
)

pep_25 <- readRDS(
  fs::path(scenarios_dir, "merged_tibbles", "df__pep_25.rds")
)

pep_50 <- readRDS(
  fs::path(scenarios_dir, "merged_tibbles", "df__pep_50.rds")
)

pep_75 <- readRDS(
  fs::path(scenarios_dir, "merged_tibbles", "df__pep_75.rds")
)

# Function to calculate average care-cascade proportions
cascade_summary <- function(df, scenario_name) {

  df |>
    mutate(
      first_95  = hiv.dx / hiv.inf,
      second_95 = hiv.tx / hiv.dx,
      third_95  = hiv.supp / hiv.tx
    ) |>
    summarise(
      `1st 95: Diagnosed / HIV` = mean(first_95, na.rm = TRUE) * 100,
      `2nd 95: ART / Diagnosed` = mean(second_95, na.rm = TRUE) * 100,
      `3rd 95: Suppressed / ART` = mean(third_95, na.rm = TRUE) * 100
    ) |>
    mutate(
      Scenario = scenario_name,
      .before = 1
    )
}

# Build comparison table
cascade_table <- bind_rows(
  cascade_summary(baseline, "Baseline"),
  cascade_summary(pep_25, "PEP 25%"),
  cascade_summary(pep_50, "PEP 50%"),
  cascade_summary(pep_75, "PEP 75%")
)

# Add UNAIDS target row
cascade_table <- bind_rows(
  cascade_table,
  tibble(
    Scenario = "UNAIDS target",
    `1st 95: Diagnosed / HIV` = 95,
    `2nd 95: ART / Diagnosed` = 95,
    `3rd 95: Suppressed / ART` = 95
  )
)

print(cascade_table)
