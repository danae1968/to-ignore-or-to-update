function analyze_simulations_vba (io,params,data,modNamesAnal)
%% analyze data simulated with the VBA toolbox (fit_discounting_models_cw.m)
%% for one generating model: indifference points of the simulated data and
%% the parameters that were recovered by refitting. Results are saved in
%% io.resultsDir/simulations_vba/<model>.
io.doPlots=0;
useMod = modNamesAnal;
io.resultsDir = fullfile(io.resultsDir,'simulations_vba',useMod);
io.condNames = { 'ignore','update'}; %perform modelling for each condition
if ~exist(io.resultsDir,'dir')
    mkdir(io.resultsDir)
end
io.data = data.(useMod);
io.subNo = unique(data.(useMod)(:,1))';
io.simSubNo = io.subNo';
[perRedo]=PercentageEasy(io.data,io,1);
[ipmat]=regressionCOGED(io.data,perRedo,io);

%% recovered parameters
outputFile=fullfile(io.resultsDir,'vbaParamsN.csv');
outputFileOut=fullfile(io.resultsDir,'vbaParamsNOut.csv');
if contains(useMod,'bias')
    names={'sub','kappa_I','beta_I','bias_I','kappa_U','beta_U','bias_U'};
else
    names={'sub','kappa_I','beta_I','kappa_U','beta_U'};
end
param_data = [io.simSubNo params.ignore.(useMod) params.update.(useMod)];
write_data = num2cell(param_data);
writetable(cell2table([names;write_data]),outputFile,'writevariablenames',0)
[outliers]=findOutliers(param_data);
if ~isempty(outliers)
    writetable(cell2table([names;write_data(~ismember(io.simSubNo,outliers),:)]),outputFileOut,'writevariablenames',0)
end
end
