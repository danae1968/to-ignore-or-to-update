function dataSim = simulations(io)
%%% Simulates choices from the parameters fitted by modelDiscCurv.m (for
%%% every model and participant, io.numSims times), then re-analyses the
%%% simulated data like the real data (indifference points, model fits;
%%% analyze_simulations.m) for parameter recovery and model recovery.
%%% io.dataDir: folder with modelsBiasComp.mat of the real data (Pooled);
%%% io.resultsDir: output folder (Pooled/simulations).

filename=fullfile(io.dataDir,'modelsBiasComp.mat');
load(filename,'model_results');

saveDir=fullfile(io.resultsDir,'simulatedDataN.mat');

tic
%% extract parameters from all models
[biasTask,biasI,biasU]=deal(struct()); % stay empty if no model with bias is simulated
for n=1:length(io.modNames)
    useMod=io.modNames{n};
    for sub=1:length(model_results.params)
        if any(strcmp(useMod,model_results.model_names))
            modInd= strcmp(model_results.model_names,useMod);
            discountTask(sub).(useMod) = [model_results.params{sub,find(strcmp(model_results.model_names,useMod)),1}(1)]; %discounting factor kappa is the first parameter in matrix
            discountI(sub).(useMod) = [model_results.params{sub,find(strcmp(model_results.model_names,useMod)),2}(1)];
            discountU(sub).(useMod) = [model_results.params{sub,find(strcmp(model_results.model_names,useMod)),3}(1)];
            
            betaTask(sub).(useMod) = model_results.params{sub,find(strcmp(model_results.model_names,useMod)),1}(2); %inverse temperature beta is the second parameter
            betaI(sub).(useMod) = model_results.params{sub,find(strcmp(model_results.model_names,useMod)),2}(2);
            betaU(sub).(useMod) = model_results.params{sub,find(strcmp(model_results.model_names,useMod)),3}(2);
            
            if model_results.model_params(modInd)== 3 %if bias was included (3 parameters)
                biasTask(sub).(useMod) = model_results.params{sub,find(strcmp(model_results.model_names,useMod)),1}(3); %bias is the third parameter
                biasI(sub).(useMod) = model_results.params{sub,find(strcmp(model_results.model_names,useMod)),2}(3);
                biasU(sub).(useMod) = model_results.params{sub,find(strcmp(model_results.model_names,useMod)),3}(3);
            end
        end
    end
end

%% save in table
if io.saveD
    
    fittedName = fullfile(fileparts(io.resultsDir),'fitted_params.csv');
    discountFitted=[(1:length(model_results.params))' [discountTask.parabolic]' [discountTask.hyperbolic]' [discountTask.linear]' [discountTask.exponential]'...
        [discountI.parabolic]' [discountI.hyperbolic]' [discountI.linear]' [discountI.exponential]' [discountU.parabolic]' [discountU.hyperbolic]' ...
        [discountU.linear]' [discountU.exponential]' [betaTask.parabolic]' [betaTask.hyperbolic]' [betaTask.linear]' [betaTask.exponential]'...
        [betaI.parabolic]' [betaI.hyperbolic]' [betaI.linear]' [betaI.exponential]' [betaU.parabolic]' [betaU.hyperbolic]' [betaU.linear]' [betaU.exponential]'...
        [discountTask.parabolic_bias]' [discountTask.hyperbolic_bias]' [discountTask.linear_bias]' [discountTask.exponential_bias]'...
        [discountI.parabolic_bias]' [discountI.hyperbolic_bias]' [discountI.linear_bias]' [discountI.exponential_bias]' [discountU.parabolic_bias]' [discountU.hyperbolic_bias]' ...
        [discountU.linear_bias]' [discountU.exponential_bias]' [betaTask.parabolic_bias]' [betaTask.hyperbolic_bias]' [betaTask.linear_bias]' [betaTask.exponential_bias]'...
        [betaI.parabolic_bias]' [betaI.hyperbolic_bias]' [betaI.linear_bias]' [betaI.exponential_bias]' [betaU.parabolic_bias]' [betaU.hyperbolic_bias]' [betaU.linear_bias]' [betaU.exponential_bias]'...
        [biasTask.parabolic_bias]' [biasTask.hyperbolic_bias]' [biasTask.linear_bias]' [biasTask.exponential_bias]' [biasI.parabolic_bias]' [biasI.hyperbolic_bias]' [biasI.linear_bias]' [biasI.exponential_bias]' ...
        [biasU.parabolic_bias]' [biasU.hyperbolic_bias]' [biasU.linear_bias]' [biasU.exponential_bias]'];
    
    names= {'subNo', 'k_par','k_hyp','k_lin','k_exp', 'kI_par','kI_hyp','kI_lin','kI_exp', 'kU_par','kU_hyp','kU_lin','kU_exp'...
        'b_par','b_hyp','b_lin','b_exp', 'bI_par','bI_hyp','bI_lin','bI_exp', 'bU_par','bU_hyp','bU_lin','bU_exp' ...
        'k_par_bias','k_hyp_bias','k_lin_bias','k_exp_bias', 'kI_par_bias','kI_hyp_bias','kI_lin_bias','kI_exp_bias', 'kU_par_bias','kU_hyp_bias','kU_lin_bias','kU_exp_bias'...
        'b_par_bias','b_hyp_bias','b_lin_bias','b_exp_bias', 'bI_par_bias','bI_hyp_bias','bI_lin_bias','bI_exp_bias', 'bU_par_bias','bU_hyp_bias','bU_lin_bias','bU_exp_bias' ...
        'bias_par_bias','bias_hyp_bias','bias_lin_bias','bias_exp_bias', 'biasI_par_bias','biasI_hyp_bias','biasI_lin_bias','biasI_exp_bias', 'biasU_par_bias','biasU_hyp_bias','biasU_lin_bias','biasU_exp_bias'};
    
    writetable(cell2table([names;num2cell(discountFitted) ]),fittedName,'writevariablenames',0)
end

%% retrieve task design
design= load(filename,'rewardHard','dataN'); %task design used in modelling

%experiment parameters
hardOffer=unique(design.rewardHard); % normalized reward of the effortful offer
cond=[0 2]; %conditions(ignore update)
Nsubs=length(discountTask);
choiceOptions=[0 1];

hardTrial=design.dataN(design.dataN(:,1)==101, 2:4); %pick trial set up (condition, set size, offer) from any subject (101)

%% run Simulations
dataSim=struct;

simSub=1;%simulated subject number
for n=1:length(io.modNames)
    useMod=io.modNames{n};
    if any(strcmp(useMod,model_results.model_names))
        modInd= strcmp(model_results.model_names,useMod);
        dataSim.(useMod)=[];
        for N=1:io.numSims
            for subInd=1:Nsubs
                for condition=cond
                    randomTrial = hardTrial(randperm(size(hardTrial, 1)), :);
                    trialData=randomTrial(randomTrial(:,1)==condition,:);
                    effort=trialData(:,2)/max(trialData(:,2)); rewardEasy=trialData(:,3)/max(trialData(:,3)); %normalize model inputs
                    % find separate discounting factor per condition
                    switch condition
                        case 0
                            discount=discountI(subInd).(useMod);
                            beta=betaI(subInd).(useMod);
                        case 2
                            discount=discountU(subInd).(useMod);
                            beta=betaU(subInd).(useMod);
                    end
                    
                    rewardHard=hardOffer*ones(length(rewardEasy),1);
                    switch useMod
                        case {'hyperbolic', 'hyperbolic_bias'}
                            hard_value = rewardHard ./ ( 1 +(discount .* effort));
                        case {'linear', 'linear_bias'}
                            hard_value =   rewardHard - (discount .* effort);
                        case {'parabolic', 'parabolic_bias'}
                            hard_value = rewardHard - (discount .* effort.^2);
                        case {'exponential' , 'exponential_bias'}
                            hard_value =   rewardHard .*exp(-discount .* effort);
                    end
                    easy_value=rewardEasy;
                    if model_results.model_params(modInd)== 2 %if bias was included (3 parameters)
                        prob =  exp(beta.*hard_value)./(exp(beta.*easy_value) + exp(beta.*hard_value));
                    elseif model_results.model_params(modInd)== 3
                        switch condition
                            case 0
                                bias=biasI(subInd).(useMod);
                            case 2
                                bias=biasU(subInd).(useMod);
                        end
                        prob =  exp((beta.*hard_value) + bias)./(exp(beta.*easy_value) + exp((beta.*hard_value) + bias));
                    end
                    %simulate choices based on probabilities
                    choices=nan(length(prob),1);
                    for i=1:length(prob)
                        choices(i)=randsample(choiceOptions,1,true,[prob(i) 1-prob(i)]);
                    end
                    
                    simSubNo=repmat(simSub,length(prob),1);
                    discountGen=repmat(discount,length(prob),1); %discounting factor that generated data
                    betaGen = repmat(beta, length(prob),1);
                    subIndGen = repmat(subInd, length(prob),1);
                    dataSim.(useMod)=[dataSim.(useMod);[simSubNo trialData choices subIndGen discountGen betaGen]];
                end
                simSub=simSub+1;
            end
        end
    end
end

save(saveDir,'dataSim')
timeSimulations=toc

%% analyze simulated data and perform parameter recovery
fitparam.discountTask = discountTask;
fitparam.discountI = discountI;
fitparam.discountU = discountU;
fitparam.biasTask = biasTask;
fitparam.biasI = biasI;
fitparam.biasU = biasU;
fitparam.betaTask = betaTask;
fitparam.betaI = betaI;
fitparam.betaU = betaU;

io.simModNames = io.modNames;

cell_io = repmat({io},1,numel(1:length(io.simModNames)));
cell_model_results = repmat({model_results},1,numel(1:length(io.simModNames)));
cell_fit_param = repmat({fitparam},1,numel(1:length(io.simModNames)));
cell_dataSim = repmat({dataSim},1,numel(1:length(io.simModNames)));

% one job per generating model: on the cluster with FieldTrip's
% qsubcellfun if available, otherwise one after the other on this computer
if exist('qsubcellfun','file')
    qsubcellfun(@analyze_simulations, cell_io, cell_model_results, cell_fit_param, cell_dataSim, io.simModNames ,'memreq', 6*1024^3, 'timreq', 45*60*60);
else
    cellfun(@analyze_simulations, cell_io, cell_model_results, cell_fit_param, cell_dataSim, io.simModNames);
end

%% model recovery
for modIndR = 1:length(io.modNames)
    useModR = io.modNames{modIndR};
    bestModI =[]; bestModU=[];
    io.resultsDir = fullfile(io.dataDir,'simulations',useModR);
    load(fullfile( io.resultsDir,'modelsBiasComp.mat'),'model_results'); % models refitted to data simulated with useModR
    like_ignore = model_results.bic(:,:,2);
    like_update = model_results.bic(:,:,3);
    
    for sub = 1:length(model_results.params)
        bestModI = [bestModI;ismember(like_ignore(sub,:),min(like_ignore(sub,:)))];
        bestModU = [bestModU;ismember(like_update(sub,:),min(like_update(sub,:)))];
    end
    oEf_refit.ignore.(useModR) = sum(bestModI)/length(model_results.params)';
    oEf_refit.update.(useModR) = sum(bestModU)/length(model_results.params)';
end

if io.saveD
    ig_of=structfun(@transpose,oEf_refit.ignore,'UniformOutput',false);
    ignore_oF =struct2table(ig_of);
    writetable(ignore_oF,fullfile(io.dataDir,'ignore_of_fmin.csv'),'writevariablenames',1)
    up_of=structfun(@transpose,oEf_refit.update,'UniformOutput',false);
    update_oF =struct2table(up_of);
    writetable(update_oF,fullfile(io.dataDir,'update_of_fmin.csv'),'writevariablenames',1)
end
end

