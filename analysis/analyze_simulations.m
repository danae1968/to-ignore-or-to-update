function analyze_simulations (io,model_results,fit_param,dataSim,modNamesAnal)
%%% Analyses the data simulated with one model (modNamesAnal) like the real
%%% data: ratio of effortful choices, indifference points
%%% (regressionCOGED.m) and refitting all discounting models
%%% (modelDiscCurv.m, modelingAnal.m) for parameter and model recovery.
%%% Results are saved in io.dataDir/simulations/<model>.
io.doPlots=0;
useMod = modNamesAnal;
if any(strcmp(useMod,model_results.model_names))
    io.resultsDir = fullfile(io.dataDir,'simulations',useMod);
    io.condNames = {'across', 'ignore','update'}; %perform modelling for each condition or across
    if ~exist(io.resultsDir,'dir')
        mkdir(io.resultsDir)
    end
    io.data = dataSim.(useMod);
    io.subNo = unique(dataSim.(useMod)(:,1))';
    io.subNr = io.subNo'; % io.subNr is a different variable because raw data subs were pooled and outliers excluded. Here represents sim data
    [perRedo]=PercentageEasy(io.data,io,1);
    [ipmat]=regressionCOGED(io.data,perRedo,io);

    % re-run modelling with simulated data
    io.dataType = 'simulated';
    io.fit_param = fit_param;
    sim_mod_results = modelDiscCurv(io);
    modelingAnal(io,sim_mod_results,io.dataType)
end
end
