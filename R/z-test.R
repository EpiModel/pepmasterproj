
source("R/A-networks/workflow-networks.R")
source("R/B-model_dev/1-netsim_run.R")
source("R/C-calibration/1-ballpark_calib.R")
source("R/C-calibration/2-manual_calib_assess.R")
source("R/C-calibration/3-choose_restart.R")
source("R/D-interventions/1-debug_modules.R")
source("R/D-interventions/2-scenarios_run.R")
source("R/D-interventions/3-process_tables.R")
source("R/D-interventions/4-process_plots.R")

source("R/D-interventions/workflow-intervention.R")

source("R/B-model_dev/2-debug_modules.R")

# listening to the git

#a-networks
source("R/A-networks/1-estimation.R")
source("R/A-networks/2-diagnostics.R")
source("R/A-networks/3-assess.R")

#b-model_dev
source("R/B-model_dev/1-netsim_run.R")
source("R/B-model_dev/2-debug_modules.R")
source("R/B-model_dev/3-scenarios_run.R")
source("R/B-model_dev/4-scenarios_assess.R")

Notes
- our script is now successfully working at 0 25 50 and 75 (:
