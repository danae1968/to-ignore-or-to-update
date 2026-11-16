# To ignore or to update
Data and analysis scripts for the paper:

Papadopetraki, D., Froböse, M. I., Westbrook, A., Zandbelt, B. B., & Cools, R. (2025). Shielding working memory from distraction is more effortful than flexible updating. *Scientific Reports*, 15, 13512. https://doi.org/10.1038/s41598-025-96980-x

Included: raw data files, analysis code, derivative data and interactive JASP statistics output files.


## Installation

Get the data and code as follows:

If you have git installed, open a terminal and run the following command

    git clone https://github.com/danae1968/to-ignore-or-to-update.git

If you don't have git installed, you can also download the code as a ZIP file.

**Requirements**

- MATLAB with the Statistics and Machine Learning Toolbox
- R with the packages lme4, reshape2, tidyverse, ggpubr, Rmisc, cowplot, effectsize, rstatix and afex (`colorwheel_plots.Rmd` installs missing packages itself)
- Optional, only for the exploratory VBA models: the [VBA toolbox](https://github.com/MBB-team/VBA-toolbox), placed in `analysis/VBA-toolbox` (or set `io.vbaDir` in `CW_analysis.m`)


## Repository structure

    analysis/      analysis code (MATLAB and R)
    analysis/jv10/ JV10 toolbox for precision and bias of circular responses (Bays et al., 2009)
    data/          raw data, per experiment and task
    derivatives/   output of the analysis scripts, per experiment and pooled


## Completely raw Data
Data files are split in two different experiment folders. Experiment 2 (62 participants) is a direct replication of experiment 1 (28 participants) with a higher sample size.

**Colorwheel task data structure:**

	Main data file: ColorFun_sX.mat, where X is subject number.

	Main variables:
	 data.respDif: absolute deviance from correct color; trial accuracy index
	 data.setsize: trial demand level, number of squares
	 data.type: trial condition; 0 for Ignore, 2 for Update
	 data.rt: trial reaction time; registered mouseclick on colorwheel

	Color sensitivity file: ColorTest_sX.mat
	Practice file: ColorFun_sX_practice.mat

**COGED data structure:**

	Main data file: ColorFunChoice_sX.mat

	Main variables:
	 data.version: index of COGED version. 1 for task vs no effort choices, 2 for ignore vs update choices
	 data.typeTask:
	 data.easyOffer: amount of money offered for the presumably easy offer (no redo/effort for version 1 and update for version 2)
	 data.choiceRT: reaction time of choice
	 data.condition: 0 for ignore, 2 for update, only relevant for version 1 choices
	 data.choice: trial choice; 1 for easy offer and 2 for hard offer
	 data.sz: trial demand level, number of squares they are choosing for

	Practice file: ColorFunChoice_sX_practice.mat


## Analysis scripts

All paths are relative to the repository, so the scripts run wherever it is cloned.

**MATLAB** — main script `analysis/CW_analysis.m`. Select the analysis steps in its `todo` section and run it:

1. colour sensitivity test (`colorTestAnalysis.m`)
2. colorwheel working memory task: deviance, RTs and precision (`performanceTrialWise.m`, `performanceCW.m`, `precisionCW.m`)
3. COGED task vs no effort choices: indifference points (`choicesTrialWise.m`, `PercentageEasy.m`, `regressionCOGED.m`)
4. COGED ignore vs update choices (`DirectComparisonAnalysis.m`)
5. effort discounting models, both experiments pooled (`modelDiscCurv.m`, `modelingAnal.m`)
6. simulations, parameter and model recovery (`simulations.m`, `analyze_simulations.m`)
7. exploratory: the same models fitted with the VBA toolbox; not reported in the manuscript (`fit_discounting_models_cw.m`, `find_fun_name.m`, `analyze_simulations_vba.m`)

Steps 1-4 run for both experiments. Steps 5-7 use the step 3 output of both experiments and the list of included participants in `derivatives/Pooled/correlationsIPsPooled.csv`.

**R**

- `MixedModelsDirectComparison.R`: mixed effects models of the ignore vs update choices
- `mixedModelsAnalysis.Rmd`: mixed effects models of the task vs no effort choices; set the `experiment` parameter to 1, 2 or 3 (pooled)
- `colorwheel_plots.Rmd`: figures of the manuscript (uses `corPlot.R` and `confMatrix.R`)

**Colorwheel output files** (`derivatives/ExperimentX/Colorwheel`):

	MedianAccOut.csv & MedianAccOut.jasp: deviance analyses files
	MedianRTOut.csv & MedianRTOut.jasp: RT analyses files
	precision.csv, precisionBias.csv: precision and bias relative to the target colour (precisionLure*.csv: relative to the lure colour)
	performanceRBeh.csv: performance raw data in a matrix per trial

**COGED output files** (`derivatives/ExperimentX/COGED`):

	IPmatrixOut.csv & IPmatrixOut.jasp: task versus no effort choice analyses files
	IPDirectOut.csv & IPDirectOut.jasp: ignore versus update choice analyses files
	choicesRNR.csv: task versus no effort raw data in a matrix trialwise
	choicesRDir.csv: ignore versus update raw data in a matrix trialwise

The above csv file names without the -Out (outlier) ending are the derivative analysis files including outliers.

**Pooled output files** (`derivatives/Pooled`):

	correlationsIPsPooled.csv & correlationsIPsPooled.jasp: data pooled from both experiments for correlation between performance and preference
	discParamsN.csv: parameters and winning model per participant of the discounting models
	simulations/: indifference points and refitted models of the simulated data, per generating model

Model fits (`.mat`, `.RData`) are not included because of their size; the scripts above re-create them.

## Contact

danaepapadopetraki@gmail.com
