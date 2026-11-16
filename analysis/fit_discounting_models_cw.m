function params = fit_discounting_models_cw(io,todo)
%% function to fit and compare discounting models with the VBA toolbox
%Danae Papadopetraki November 2021
%Exploratory alternative to modelDiscCurv.m/simulations.m (not reported in
%the paper).
%inputs: io: struct defined in CW_analysis.m (io.data: pooled choices,
%io.subNr: included participants, io.vbaDir, io.resultsDir, io.numSims,
%io.saveD). todo: modelFit (fit models), simulate (simulate data from the
%fitted parameters and refit, parameter recovery), refit (fit all models to
%simulated data, model recovery).
%outputs: params: posterior means of the observation parameters per
%condition and model. The discounting parameter is estimated in log space
%(phi(1) = log(kappa), see find_fun_name.m), so the k columns of
%fit_params_vba.csv are log(kappa). Files in io.resultsDir: mods.mat, fit_params_vba.csv,
%sim_mods.mat, ignore_of.csv, update_of.csv, simulations_vba/<model>/.

%% directories
addpath(genpath(io.vbaDir)) % VBA toolbox (https://github.com/MBB-team/VBA-toolbox)

%% load data
data= io.data;
num_sim_reps = io.numSims;
% remove NaN trials (no response)
dataN= data(~isnan(data(:,5)),:);
subNo=dataN(:,1);condition=dataN(:,2);high_effort=dataN(:,3);low_reward=dataN(:,4);choice=1-dataN(:,5);
low_effort = zeros(size(dataN,1),1); % add no effort
high_reward = 2*(ones(size(dataN,1),1)); %add reward for high effort
%% model parameters
% Build options and dim structures for model inversion
dim.n_theta = 0;
dim.n = 0;
dim.p = 1;
options.dim = dim;
options.sources.type = 1; %binomial
options.task_names = {'ignore','update','across'};
options.model_names= {'linear','parabolic','hyperbolic', 'exponential','linear_bias','parabolic_bias','hyperbolic_bias', 'exponential_bias'};
options.verbose=0;
options.DisplayWin = false;
%% fit models

iter=1;
include_subs= io.subNr;
if todo.modelFit
    F=struct();
    params=struct();
    fit_bic = struct();
    fit_aic = struct();
    
    for condNo = 1:length(options.task_names)
        cond = options.task_names{condNo};
        for modInd = 1:length(options.model_names)
            useMod = options.model_names{modInd};
                            u_all = [high_reward'; high_effort' ; low_reward'; low_effort'];
            F.(cond).(useMod)=[]; params.(cond).(useMod)=[];fit_bic.(cond).(useMod)=[];
            fit_aic.(cond).(useMod)=[];
            for sub = include_subs'
                %generate input matrix for VBAstate(high effort, high reward, low
                %effort, low reward)
                switch cond
                    case 'across'
                        subChoices = choice(subNo==sub);
                        u= u_all(:,subNo'==sub);
                    case 'ignore'
                        subChoices = choice(subNo==sub & condition ==0);
                        u= u_all(:,subNo'==sub & condition'==0);
                    case 'update'
                        subChoices = choice(subNo==sub & condition ==2);
                        u= u_all(:,subNo'==sub & condition'==2);
                end
                %format must be: high effort first, high reward, low effort, low
                %reward             
                fun_name = find_fun_name(useMod);
                if contains(useMod, 'bias')
                    dim.n_phi = 3; %D.P. observation parameters
                else
                    dim.n_phi = 2;
                end
                
                options.g_fname = fun_name;
                [posterior, out] = VBA_NLStateSpaceModel(subChoices', u, [], fun_name, dim, options);
                fit_bic.(cond).(useMod) = [fit_bic.(cond).(useMod);out.fit.BIC'];
                fit_aic.(cond).(useMod) = [fit_aic.(cond).(useMod);out.fit.AIC'];
                F.(cond).(useMod) = [F.(cond).(useMod); out.F'];
                params.(cond).(useMod) = [params.(cond).(useMod); posterior.muPhi'];
                iter=iter+1;
            end
        end
    end
    %save model parameters
    if io.saveD
        save(fullfile(io.resultsDir,'mods.mat'),'F','params','fit_bic')
    end
    fit_names = {'subNo'}; %first column is subno
    fit_params = io.subNr;
    fit_conds = fieldnames(params);
    for condInd = 1:length(fit_conds)
        cond = fit_conds{condInd};
        fit_mods = fieldnames(params.(cond));
        for modInd = 1:length(fit_mods)
            useMod = fit_mods{modInd};
            fit_params = [fit_params params.(cond).(useMod)];
            switch cond
                case 'ignore'
                    pre = 'I';
                case 'update'
                    pre = 'U';
                case 'across'
                    pre ='';
            end
            suf = useMod(1:3);
            if contains(useMod, 'bias')
                fit_name = {strcat('k',pre,'_',suf,'_bias') strcat('b',pre,'_',suf,'_bias') strcat('bias',pre,'_',suf,'_bias') };
            else
                fit_name = {strcat('k',pre,'_',suf) strcat('b',pre,'_',suf)};
            end
            fit_names = [fit_names fit_name];
        end
    end
    fit_params= num2cell(fit_params);
    outputParamsFile = fullfile(io.resultsDir,'fit_params_vba.csv');
    if io.saveD
        writetable(cell2table([fit_names;fit_params]),outputParamsFile,'writevariablenames',0)
    end
    %% compare models

    for condNo = 1:length(options.task_names)
        cond = options.task_names{condNo};
        [p(condNo), o(condNo)] = VBA_groupBMC([F.(cond).linear';F.(cond).parabolic';F.(cond).hyperbolic';F.(cond).exponential';F.(cond).linear_bias';F.(cond).parabolic_bias';F.(cond).hyperbolic_bias';F.(cond).exponential_bias']);
        [~, idxWinner] = max(o(condNo).Ef);
        fprintf('The best model for %s is the model %s: Ef = %4.3f (pxp = %4.3f)\n',cond,options.model_names{idxWinner}, o(condNo).Ef(idxWinner), o(condNo).pxp(idxWinner));
    end
%     
    %% compare between conditions
        F_between = [F.ignore.linear';F.ignore.parabolic';F.ignore.hyperbolic';F.ignore.exponential';F.ignore.linear_bias';F.ignore.parabolic_bias';F.ignore.hyperbolic_bias';F.ignore.exponential_bias'];
        F_between(:,:,2) = [F.update.linear';F.update.parabolic';F.update.hyperbolic';F.update.exponential';F.update.linear_bias';F.update.parabolic_bias';F.update.hyperbolic_bias';F.update.exponential_bias'];
        [ep, o] = VBA_groupBMC_btwConds(F_between) ;
    
end
%% simulate data
if todo.simulate
    if ~exist('params','var')
        load(fullfile(io.resultsDir,'mods.mat'),'params')
    end
    
    sim_subNo = 1;
    options.sim_task_names = {'ignore','update'};
%     clear options.priors
    for modInd = 1:length(options.model_names)
        useMod = options.model_names{modInd};
        sim_data.(useMod)=[]; F_sim.ignore.(useMod)=[]; params_sim.ignore.(useMod)=[];
        F_sim.update.(useMod)=[]; params_sim.update.(useMod)=[];
        F_refit.ignore.(useMod) =[]; params_refit.ignore.(useMod)=[];
        F_refit.update.(useMod) =[]; params_refit.update.(useMod)=[];
        
        fun_name = find_fun_name(useMod);
        
                    u_all = [high_reward'; high_effort' ; low_reward'; low_effort'];
                if contains(useMod, 'bias')
                    dim.n_phi = 3; %D.P. observation parameters
                else
                    dim.n_phi = 2;
                end
        for N=1:num_sim_reps
            for ind = 1:length(include_subs)
                
                for condNr = 1:length(options.sim_task_names)
                    cond = options.sim_task_names{condNr};
                    fitted_params = params.(cond).(useMod);
                    % trial design of one participant (subject 5) is used for all simulations
                    switch cond
                        case 'ignore'
                            u= u_all(:,subNo'==5 & condition'==0);
                            condNo = 0;
                        case'update'
                            u= u_all(:,subNo'==5 & condition'==2);
                            condNo = 2;
                    end
                    nTrials = size(u,2);
                    phi_sim = fitted_params(ind,:);
                if contains(useMod, 'bias')
                    dim.n_phi = 3; %D.P. observation parameters
                else
                    dim.n_phi = 2;
                end
                    [y] = VBA_simulate (nTrials,[],fun_name,[],phi_sim,u,[],[],options);
                    [posterior,out] = VBA_NLStateSpaceModel(y,u,[],fun_name,dim,options);
                    % y=1 is choosing the effortful option; stored as 1-y to match the raw data coding (0: effortful, see choicesTrialWise.m)
                    sim_data.(useMod) = [sim_data.(useMod); [repmat(sim_subNo,nTrials,1) repmat(condNo,nTrials,1) u(2:3,:)' 1-y']];
                    F_sim.(cond).(useMod) = [F_sim.(cond).(useMod); out.F'];
                    params_sim.(cond).(useMod) = [params_sim.(cond).(useMod); posterior.muPhi'];
                    
                    if todo.refit
                        for modIndR = 1:length(options.model_names)
                            useModR = options.model_names{modIndR};
                            fun_nameR = find_fun_name(useModR);
                            if ~isfield(F_refit.(cond).(useMod),useModR)
                                F_refit.(cond).(useMod).(useModR)=[]; params_refit.(cond).(useMod).(useModR)=[];
                            end
                if contains(useModR, 'bias')
                    dim.n_phi = 3; %D.P. observation parameters
                else
                    dim.n_phi = 2;
                end
                            [~, out_refit] = VBA_NLStateSpaceModel(y, u, [], fun_nameR, dim, options);
                            F_refit.(cond).(useMod).(useModR) = [F_refit.(cond).(useMod).(useModR); out_refit.F'];
                        end
                    end
                end
                sim_subNo = sim_subNo+1;
                
            end
            
        end
        
        %analyze simulated data
        analyze_simulations_vba(io,params_sim,sim_data,useMod)
    end
    if io.saveD
        if todo.refit
            save(fullfile(io.resultsDir,'sim_mods.mat'),'sim_data','F_sim','params_sim','F_refit','params_refit')
        else
            save(fullfile(io.resultsDir,'sim_mods.mat'),'sim_data','F_sim','params_sim')
        end
        
    end
end

%% model recovery
if todo.refit
    for condNo = 1:length(options.sim_task_names)
        cond= options.sim_task_names{condNo};
        for modIndR = 1:length(options.model_names)
            useModR = options.model_names{modIndR};
            [~, o] = VBA_groupBMC([F_refit.(cond).(useModR).linear';F_refit.(cond).(useModR).parabolic';F_refit.(cond).(useModR).hyperbolic';F_refit.(cond).(useModR).exponential';F_refit.(cond).(useModR).linear_bias';F_refit.(cond).(useModR).parabolic_bias';F_refit.(cond).(useModR).hyperbolic_bias';F_refit.(cond).(useModR).exponential_bias']);
            %             [~, idxWinner] = max(o.Ef);
            oEf_refit.(cond).(useModR) = o.Ef;
        end
    end
    if io.saveD
        ignore_oF =struct2table(oEf_refit.ignore);
        writetable(ignore_oF,fullfile(io.resultsDir,'ignore_of.csv'),'writevariablenames',1)
        update_oF =struct2table(oEf_refit.update);
        writetable(update_oF,fullfile(io.resultsDir,'update_of.csv'),'writevariablenames',1)
    end
end

end