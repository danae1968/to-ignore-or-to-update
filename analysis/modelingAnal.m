function  modelingAnal(io,varargin)

switch nargin
    case 3
        model_results = varargin{1};
        dataType = varargin{2}; 
    case    2    
        model_results = varargin{1};
        dataType = 'raw'  ;
    case 1
        filename=fullfile(io.resultsDir,'modelsBiasComp.mat');
        load(filename,'model_results');
          dataType = 'raw';
      
end

%Params per task
bic_task = model_results.bic(:,:,1);
aic_task = model_results.aic(:,:,1);

bic_I = model_results.bic(:,:,2);
aic_I = model_results.aic(:,:,2);

bic_U = model_results.bic(:,:,3);
aic_U = model_results.aic(:,:,3);

%find best model
minBic=min(mean(model_results.bic));
minAic=min(mean(model_results.aic));
indexAic=mean(model_results.aic)== minAic;
indexBic=mean(model_results.bic)== minBic;

TaskBic=mean(model_results.bic(:,:,1)); %across conditions
IgnBic=mean(model_results.bic(:,:,2));
UpdBic=mean(model_results.bic(:,:,3));

TaskAic = mean (aic_task);
IgnAic = mean(aic_I);
UpdAic = mean(aic_U);

winBicTask= model_results.model_names(indexBic(:,:,1)); %across conditions
    fprintf(1,[repmat('-',1,72),'\n'])
fprintf('best model (BIC) for task is %s\n', winBicTask{1})
winBicIgn= model_results.model_names(indexBic(:,:,2));
    fprintf(1,[repmat('-',1,72),'\n'])
fprintf('best model (BIC) for ignore is %s\n', winBicIgn{1})
winBicUpd=model_results.model_names(indexBic(:,:,3));
    fprintf(1,[repmat('-',1,72),'\n'])
fprintf('best model (BIC) for update is %s\n', winBicUpd{1})
winAicTask= model_results.model_names(indexAic(:,:,1));
winAicIgn= model_results.model_names(indexAic(:,:,2));
winAicUpd=model_results.model_names(indexAic(:,:,3));


if io.doPlots
    figure;
    barh([TaskBic;IgnBic;UpdBic]')
    xlabel('Bayesian Information Criterion')
    legend('Task','Ignore','Update')
    yticks(1:length(model_results.model_names))
    yticklabels(strrep(model_results.model_names,'_',' '))
    ytickangle(15)

    figure;
    barh([TaskAic;IgnAic;UpdAic]')
    xlabel('Akaike Information Criterion')
    legend('Task','Ignore','Update')
    yticks(1:length(model_results.model_names))
    yticklabels(strrep(model_results.model_names,'_',' '))
    ytickangle(15)
end
    
%discounting parameter of winning model

kappa = NaN(length(model_results.params),length(io.condNames));
beta = NaN(length(model_results.params),length(io.condNames));
bias = NaN(length(model_results.params),length(io.condNames));

for sub=1:length(model_results.params)
    for conInd=1:length(io.condNames)% one column for each condition (across/ignore/update)
        kappa(sub,conInd)=[model_results.params{sub,indexBic(:,:,conInd),conInd}(1)];
        beta(sub,conInd)=[model_results.params{sub,indexBic(:,:,conInd),conInd}(2)];
        if numel(model_results.params{sub,indexBic(:,:,conInd),conInd})> 2 % if there are more than two params
        bias(sub,conInd)=[model_results.params{sub,indexBic(:,:,conInd),conInd}(3)];      
        end
    end
end

%% find best model per participant
minPP=min(model_results.bic,[],2);
indexPP=model_results.bic==minPP;
index_bt = bic_task==min(bic_task,[],2);
index_at = aic_task==min(aic_task,[],2);
index_bi = bic_I==min(bic_I,[],2);
index_bu = bic_U==min(bic_U,[],2);
index_ai = aic_I==min(aic_I,[],2);
index_au = aic_U==min(aic_U,[],2);

for n=1:size(bic_task,2)
%     bestMod(indexPP(:,n)==1)=n;
    bestMod_bic_task(index_bt(:,n)==1)=n;
    bestMod_aic_task(index_at(:,n)==1)=n;
    bestMod_bic_i(index_bi(:,n)==1)=n;
    bestMod_aic_i(index_ai(:,n)==1)=n;
    bestMod_bic_u(index_bu(:,n)==1)=n;
    bestMod_aic_u(index_au(:,n)==1)=n;
end

bestMod = [ bestMod_bic_task' bestMod_aic_task' bestMod_bic_i' bestMod_aic_i' bestMod_bic_u' bestMod_aic_u'];

bestModName=model_results.model_names(bestMod);


%% modeling results based on condition

if strcmp(dataType,'raw')

filenameDir=fullfile(io.resultsDir,'directPooled.csv'); %direct comparison choice results
direct=readtable(filenameDir);
incl_data = readtable(fullfile(io.resultsDir,'correlationsIPsPooled.csv'));
devI_U = incl_data.devI_devU;
prefI=intersect(direct.subNo(direct.IP>2),io.subNr);
prefU=intersect(direct.subNo(direct.IP<2),io.subNr);
devI=intersect(io.subNr(devI_U<0),io.subNr);
devU=intersect(io.subNr(devI_U>0),io.subNr);

bicN=[io.subNr model_results.bic(:,:,1)]; %across condition
aicN=[io.subNr model_results.aic(:,:,1)]; %across condition

ignoreModPrefBic=mean(bicN(ismember(io.subNr,prefI),2:end));
updateModPrefBic=mean(bicN(ismember(io.subNr,prefU),2:end));

ignoreModDevBic=mean(bicN(ismember(io.subNr,devI),2:end));
updateModDevBic=mean(bicN(ismember(io.subNr,devU),2:end));

ignoreModPrefAic=mean(aicN(ismember(io.subNr,prefI),2:end));
updateModPrefAic=mean(aicN(ismember(io.subNr,prefU),2:end));

ignoreModDevAic=mean(aicN(ismember(io.subNr,devI),2:end));
updateModDevAic=mean(aicN(ismember(io.subNr,devU),2:end));


%make variable for preference based on direct comparison
preference=NaN(length(io.subNr),1);
performance=NaN(length(io.subNr),1);

preference(ismember(io.subNr,prefI))=0;
preference(ismember(io.subNr,prefU))=2;
performance(ismember(io.subNr,devI)) = 0;
performance(ismember(io.subNr,devU)) = 2;

end

%% save data

if io.saveD
    outputFile=fullfile(io.resultsDir,'discParamsN.csv');
    outputFileOut=fullfile(io.resultsDir,'discParamsNOut.csv');
    
    if strcmp(dataType,'raw')
    names={'sub','kappa','kappa_I','kappa_U','beta','beta_I','beta_U','preference', 'performance', 'bias', 'biasI','biasU', 'winModTaskBic', 'winModTaskAic', 'winModIgnBic', 'winModIgnAic', 'winModUpdBic', 'winModUpdAic'};
    write_data = num2cell([io.subNr kappa beta preference performance bias]); write_data = [write_data,bestModName];
    writetable(cell2table([names;write_data]),outputFile,'writevariablenames',0)
    paramMat=[io.subNr kappa beta bias];
    [outliers,paramOut]=findOutliers(paramMat(paramMat(:,1)~=46,:));outliers=[outliers;46]; %add participant who pressed only 1 button in outliers and estimate outliers without them
    
    incl_data.kappa = kappa(:,1);  incl_data.kappaI = kappa(:,2);  incl_data.kappaU = kappa(:,3); 
    incl_data.beta = beta(:,1);  incl_data.betaI = beta(:,2);  incl_data.betaU = beta(:,3); 
    incl_data.bias = bias(:,1);  incl_data.biasI = bias(:,2);  incl_data.biasU = bias(:,3); 
    writetable(incl_data, fullfile(io.resultsDir, 'dataPooled.csv'))
    
    if ~isempty(outliers)
        writetable(cell2table([names;write_data(~ismember(io.subNr,outliers),:)]),outputFileOut,'writevariablenames',0)
    end
    elseif strcmp(dataType,'simulated')
    names={'sub','kappa','kappa_I','kappa_U','beta','beta_I','beta_U','bias', 'biasI','biasU', 'winModTaskBic', 'winModTaskAic', 'winModIgnBic', 'winModIgnAic', 'winModUpdBic', 'winModUpdAic'};
    write_data = num2cell([io.subNr kappa beta bias]); write_data =[write_data,bestModName];
    writetable(cell2table([names;write_data]),outputFile,'writevariablenames',0)
    
    paramMat=[io.subNr kappa beta bias];
    [outliers,paramOut]=findOutliers(paramMat);   
    if ~isempty(outliers)
        writetable(cell2table([names;write_data(~ismember(io.subNr,outliers),:)]),outputFileOut,'writevariablenames',0)
    end
    end
    
    
end
