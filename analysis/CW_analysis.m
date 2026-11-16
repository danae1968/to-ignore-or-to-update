% Wrapper script for the analyses of the paper:
% "Shielding working memory from distraction is more effortful than flexible updating"
%
% Paths are resolved relative to this file, so the script can be run from
% anywhere as long as the repository layout (analysis/, data/, derivatives/)
% is kept.
%
% Pipeline (switch steps on/off in the "todo" section below):
%  1. Colour sensitivity test         colorTestAnalysis.m
%  2. Colorwheel working memory task  performanceTrialWise.m, performanceCW.m,
%                                     precisionCW.m (uses jv10/)
%  3. COGED: task vs no effort        choicesTrialWise.m, PercentageEasy.m,
%                                     regressionCOGED.m
%  4. COGED: ignore vs update         choicesTrialWise.m, PercentageEasy.m,
%                                     DirectComparisonAnalysis.m
%  5. Discounting models (pooled)     modelDiscCurv.m, modelingAnal.m
%  6. Simulations, parameter and      simulations.m, analyze_simulations.m
%     model recovery (pooled)
%  7. VBA models (exploratory, not    fit_discounting_models_cw.m,
%     reported in the paper)          find_fun_name.m, analyze_simulations_vba.m
%
% Steps 1-4 are run separately for each experiment (1: original,
% 2: replication). Steps 5-7 pool both experiments and need the outputs of
% step 3 for both experiments, plus derivatives/Pooled/correlationsIPsPooled.csv
% (included participants) and derivatives/Pooled/directPooled.csv.
%
% Statistics and figures are done in R: MixedModelsDirectComparison.R,
% mixedModelsAnalysis.Rmd and colorwheel_plots.Rmd.

clear all
io=struct();

io.analysisDir=fileparts(mfilename('fullpath'));
io.projectDir=fileparts(io.analysisDir);
addpath(io.analysisDir, fullfile(io.analysisDir,'jv10'))

io.experiments = [1 2]; % 1: original experiment, 2: replication

io.saveD = 1;          % save output files
io.doPlots = 1;        % group-level plots
io.plotIndividual = 0; % per-participant regression plots (2 figures per participant)

% Which analyses to run
todo.Colortest = 1;   % colour sensitivity test
todo.Colorwheel = 1;  % colorwheel working memory task performance and precision
todo.ChoiceNR = 1;    % choices task vs no effort
todo.ChoiceD = 1;     % direct comparison choices (ignore vs update)
todo.modeling = 1;    % modelling of the discounting curve
todo.simulations = 0; % simulations + parameter/model recovery (slow: refits every simulated participant)
todo.vba = 0;         % exploratory VBA modelling (needs the VBA toolbox, see step 7)

for experiment = io.experiments
    io.experiment = experiment;
    if io.experiment==1
        io.lost=4:7; % lost data files
        io.subNo=1:32; io.subNo(io.lost)=[];
    else
        io.lost=[];
        io.subNo=1:62;
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 1. Color sensitivity test performance analysis
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if todo.Colortest
        printHeader(sprintf('Experiment %d: colour sensitivity task',io.experiment))
        io.dataDir=fullfile(io.projectDir,'data',sprintf('Experiment%d',io.experiment),'Colorwheel');
        io.resultsDir=makeDir(fullfile(io.projectDir,'derivatives',sprintf('Experiment%d',io.experiment),'Colorwheel'));
        [colorTestMean, colorTestMed]=colorTestAnalysis(io);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 2. Colorwheel performance analysis
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if todo.Colorwheel
        printHeader(sprintf('Experiment %d: deviance, RTs and precision in the colorwheel task',io.experiment))
        io.dataDir=fullfile(io.projectDir,'data',sprintf('Experiment%d',io.experiment),'Colorwheel');
        io.resultsDir=makeDir(fullfile(io.projectDir,'derivatives',sprintf('Experiment%d',io.experiment),'Colorwheel'));

        [trialData]=performanceTrialWise(io,1);
        [statmatAcc,statmatRT,statmatSZ]=performanceCW(trialData,io);
        [precision,bias]=precisionCW(trialData,io);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 3. Choices task vs No Redo analysis
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if todo.ChoiceNR
        printHeader(sprintf('Experiment %d: indifference points for task vs no effort choices',io.experiment))
        io.dataDir=fullfile(io.projectDir,'data',sprintf('Experiment%d',io.experiment),'COGED');
        io.resultsDir=makeDir(fullfile(io.projectDir,'derivatives',sprintf('Experiment%d',io.experiment),'COGED'));

        [choicesNR]=choicesTrialWise(io,1);
        [perRedo]=PercentageEasy(choicesNR,io,1);
        [IPmatrixNR]=regressionCOGED(choicesNR,perRedo,io);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 4. Choices Ignore vs Update analysis
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if todo.ChoiceD
        printHeader(sprintf('Experiment %d: indifference points for direct comparison choices',io.experiment))
        io.dataDir=fullfile(io.projectDir,'data',sprintf('Experiment%d',io.experiment),'COGED');
        io.resultsDir=makeDir(fullfile(io.projectDir,'derivatives',sprintf('Experiment%d',io.experiment),'COGED'));

        [choicesDir]=choicesTrialWise(io,2);
        [perIgnore]=PercentageEasy(choicesDir,io,2);
        [IPmatrixD]=DirectComparisonAnalysis(choicesDir,perIgnore,io);
    end
end

%% Pooled data of both experiments (input for steps 5-7)
if todo.modeling || todo.simulations || todo.vba
    io.poolDir=makeDir(fullfile(io.projectDir,'derivatives','Pooled'));
    io.data1=csvread(fullfile(io.projectDir,'derivatives','Experiment1','COGED','choicesRNR.csv')); % experiment 1 data
    io.data2=csvread(fullfile(io.projectDir,'derivatives','Experiment2','COGED','choicesRNR.csv')); % experiment 2 data
    incl_data = readtable(fullfile(io.poolDir,'correlationsIPsPooled.csv'));
    io.subNr = incl_data.subNo(~isnan(incl_data.subNo)); % included participants of both experiments

    % ensure different subNo for the two experiments
    io.data1(:,1)=io.data1(:,1)+100;
    io.data=[io.data1 ;io.data2];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 5. Modeling the discounting curve
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if todo.modeling
    printHeader('Discount curve modeling')
    io.resultsDir=io.poolDir;
    io.condNames = {'across', 'ignore','update'}; % modelling across conditions and for each condition separately
    io.dataType = 'raw';
    model_results = modelDiscCurv(io);
    modelingAnal(io, model_results)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 6. Simulations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if todo.simulations
    printHeader('Simulations, parameter and model recovery for discount curve modeling')
    io.dataDir=io.poolDir;
    io.resultsDir=makeDir(fullfile(io.poolDir,'simulations'));
    io.numSims = 100; % number of simulations per participant
    io.modNames = {'parabolic','linear','hyperbolic','exponential','parabolic_bias','linear_bias','hyperbolic_bias','exponential_bias'};
    dataSimulated = simulations(io);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 7. VBA modeling (exploratory, not reported in the paper)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Alternative implementation of steps 5-6 with variational Bayes, using the
% VBA toolbox (https://github.com/MBB-team/VBA-toolbox). The toolbox is not
% part of this repository: download it and set io.vbaDir to its location.
if todo.vba
    printHeader('Modeling and simulations for the discount curve with the VBA toolbox')
    io.vbaDir = fullfile(io.analysisDir,'VBA-toolbox');
    if ~exist(fullfile(io.vbaDir,'VBA_NLStateSpaceModel.m'),'file')
        error('VBA toolbox not found in %s. Download it from https://github.com/MBB-team/VBA-toolbox and set io.vbaDir.',io.vbaDir)
    end
    io.resultsDir=io.poolDir;
    io.numSims = 100; % number of simulations per participant
    vbaTodo.modelFit = 1; % fit models to the data
    vbaTodo.simulate = 1; % simulate data from the fitted parameters (parameter recovery)
    vbaTodo.refit = 1;    % refit all models to the simulated data (model recovery)
    fit_discounting_models_cw(io,vbaTodo);
end

%% helper functions
function printHeader(txt)
fprintf(1,[repmat('-',1,72),'\n'])
fprintf(1,'Running ''%s''\n',txt)
end

function dirName=makeDir(dirName)
if ~exist(dirName,'dir')
    mkdir(dirName)
end
end
