function model_results = modelDiscCurv(io)
%%% Fits 8 effort discounting models (parabolic, hyperbolic, linear,
%%% exponential, each with and without a bias parameter) to the COGED task
%%% vs no effort choices of each participant with fminsearch, across
%%% conditions and separately for ignore and update. Input: io, with
%%% io.data (pooled choices, see CW_analysis.m), io.subNr (participants to
%%% fit), io.condNames, io.dataType ('raw' or 'simulated') and
%%% io.resultsDir. Output: model_results (also saved in
%%% io.resultsDir/modelsBiasComp.mat) with AIC, BIC, likelihood and
%%% parameters per participant x model x condition.

filenameCond= fullfile( io.resultsDir,'modelsBiasComp.mat');

% remove NaN trials (no response)
dataN= io.data(~isnan(io.data(:,5)),:);
subNo=dataN(:,1);cond=dataN(:,2);sz=dataN(:,3);offer=dataN(:,4);choice=1-dataN(:,5);

num_subs = length(unique(subNo));  % Number of subjects

models = { % Models to apply
    @(p, reward, rewardH, effort, chosen) prob_para(p, reward, rewardH, effort, chosen);%2
    @(p, reward, rewardH, effort, chosen) prob_hyp(p, reward,rewardH, effort, chosen);%3
    @(p, reward, rewardH, effort, chosen) prob_lin(p, reward,rewardH, effort, chosen);%1
    @(p, reward, rewardH, effort, chosen) prob_exp(p, reward, rewardH, effort, chosen);%4
    @(p, reward, rewardH, effort, chosen) prob_para_bias(p, reward, rewardH, effort, chosen);%2
    @(p, reward, rewardH, effort, chosen) prob_hyp_bias(p, reward,rewardH, effort, chosen);%3
    @(p, reward, rewardH, effort, chosen) prob_lin_bias(p, reward,rewardH, effort, chosen);%1
    @(p, reward, rewardH, effort, chosen) prob_exp_bias(p, reward, rewardH, effort, chosen);%4};
    };

model_names = {'parabolic', 'hyperbolic','linear', 'exponential' 'parabolic_bias', 'hyperbolic_bias','linear_bias', 'exponential_bias' };  % Model names
model_params = [2 2 2 2 3 3 3 3];  % Number of parameters for each model

aic = nan(num_subs, length(models));
bic = nan(num_subs, length(models));

% parameter space
min_k = 0;
max_k = Inf;
min_b = 0;
max_b = Inf;
max_bias = Inf;
min_bias = -Inf;

iter=1;
loop=1;

for condition= io.condNames
    
    for sub=io.subNr'%unique(subNo)'  % For each subject  sub =noOutliers'
        switch cell2mat(condition)
            case 'across'
                effort = sz(subNo == sub)/ max(sz); % Effort
                rewardEasy = offer(subNo == sub)/max(offer); % Reward for easy offer
                chosen = choice(subNo == sub); % Choice
            case 'ignore'
                effort = sz(subNo == sub & cond==0)/ max(sz); % Effort ignore
                rewardEasy = offer(subNo == sub & cond==0)/max(offer); % Reward for easy offer
                chosen = choice(subNo == sub & cond==0); % Choice
            case 'update'
                effort = sz(subNo == sub & cond==2)/ max(sz); % Effort update
                rewardEasy = offer(subNo == sub & cond==2)/max(offer); % Reward for easy offer
                chosen = choice(subNo == sub & cond==2); % Choice
        end
        
        rewardHard=2*ones(length(rewardEasy),1)/max(offer); %reward for hard offer was always 2 for us
        
        for modNum = 1:length(models)  % For each model
            pfunc = (models{modNum});
            
            %constrain parameters based on fitted data
%                 
            %eps: minimum Z matlab can recognize in which Z+1=1
            neg_likelihood_func = @(p) -sum(log(eps+pfunc(p,rewardEasy,rewardHard,effort,chosen))) ;
            p{modNum}=[]; nll(modNum)=inf;
            
            for k = 1:20 % Randomise starting values
                startp(1) = rand;
                startp(2) = rand;
                % if model has 3 parameters
                if model_params(modNum)==3
                    startp(3) = rand;
                    %constrain parameters so that k[0,10], b[0,20]
                    constrained_nll = @(p) neg_likelihood_func(p) + (p(1)<min_k)*realmax + (p(1)>max_k)*realmax +(p(2)<min_b)*realmax + (p(2)>max_b)*realmax + (p(3)<min_bias)*realmax + (p(3)>max_bias)*realmax; %if negative max, if positive 0
                else
                    constrained_nll = @(p) neg_likelihood_func(p) + (p(1)<min_k)*realmax + (p(1)>max_k)*realmax +(p(2)<min_b)*realmax + (p(2)>max_b)*realmax; %if negative max, if positive 0
             
                end

                %fminsearch: nonlinear programming solver. Searches for the minimum of a problem specified by
                %pk: local minimum p (parameter), nllk: y=fun(x), where x=p/likelihood
                [pk, nllk] = fminsearch( constrained_nll, startp, optimset('MaxFunEvals',10000000,'MaxIter',10000000) );  % Find the optimal parameters
                if nllk<nll(modNum) % Is this better than previous estimates?
                    nll(modNum)=nllk; p{modNum}=pk; % If so, update the 'best' estimate
                end
                model_results.all_nll(iter,modNum,k,loop) = nllk;
                model_results.all_p{iter,modNum,k,loop}  = pk;
                clear startp
            end
            
            % For each model, store probabilities of each trial
            model_results.prob{iter,modNum,loop} =   pfunc(p{modNum},rewardEasy,rewardHard, effort, chosen);
            % AIC = -2*logL + 2*numParam; BIC = -2*logL + numParam*log(numObs)
            aic(modNum) = (2*model_params(modNum)) - (2*-nll(modNum));
            bic(modNum) = log(length(chosen)) * model_params(modNum) - (2*-nll(modNum));
            model_results.aic(iter,modNum,loop) = aic(modNum);  % AIC
            model_results.bic(iter,modNum,loop) = bic(modNum);  % BIC
            model_results.likelihood(iter,modNum,loop) = nll(modNum); % Likelihood
            model_results.params{iter,modNum,loop} = p{modNum}; % Parameters
            
        end % Next model
        iter=iter+1;
        %         sub
    end
    loop=loop+1;
    iter=1;
end %condition
model_results.models          = models;
model_results.model_names     = model_names;
model_results.model_params    = model_params;
model_results.model_condNames = io.condNames;
if strcmp(io.dataType, 'simulated')
    model_results.fit_param = io.fit_param; % parameters that generated the simulated data
end
% dataN and the model inputs of the last fit are also saved because
% simulations.m uses them to reconstruct the task design
save(filenameCond,'model_results','dataN','rewardEasy','rewardHard','effort');

%% For all these discounting functions:
% p(1) = discount parameter
% p(2) = softmax beta

function [prob, value_hard] = prob_lin(p,rewardEasy,rewardHard,effort,chosen)
discount = p(1);
beta = p(2);
value_hard = rewardHard - (discount .* effort);
value_easy = rewardEasy;
prob =  exp(beta.*value_hard)./(exp(beta.*value_easy) + exp(beta.*value_hard));
prob(~chosen) =  1 - prob(~chosen);
prob = prob(:,1);
return

function [prob, value_hard] = prob_para(p,rewardEasy,rewardHard,effort,chosen)
discount = p(1);
beta = p(2);
value_hard = rewardHard - (discount .* effort.^2);
value_easy = rewardEasy;
prob =  exp(beta.*value_hard)./(exp(beta.*value_easy) + exp(beta.*value_hard));
prob(~chosen) =  1 - prob(~chosen);
prob = prob(:,1);
return

function [prob, value_hard] = prob_hyp(p,rewardEasy,rewardHard,effort,chosen)
discount = p(1);
beta = p(2);
value_hard = rewardHard ./ ( 1 +(discount .* effort));
value_easy=rewardEasy;
prob =  exp(beta.*value_hard)./(exp(beta.*value_easy) + exp(beta.*value_hard));
prob(~chosen) =  1 - prob(~chosen);
prob = prob(:,1);
return

function [prob, value_hard] = prob_exp(p,rewardEasy,rewardHard,effort,chosen)
discount = p(1);
beta = p(2);
value_hard =   rewardHard .*exp(-discount .* effort);
value_easy=rewardEasy;
prob =  exp(beta.*value_hard)./(exp(beta.*value_easy) + exp(beta.*value_hard));
prob(~chosen) =  1 - prob(~chosen);
prob = prob(:,1);
return

% functions with bias parameter

function [prob, val] = prob_lin_bias(p,rewardEasy,rewardHard,effort,chosen)
discount = p(1);
beta = p(2);
val =   rewardHard - (discount .* effort);
base=rewardEasy;
prob =  exp((beta.*val) + p(3))./(exp(beta.*base) + exp((beta.*val) + p(3)));
prob(~chosen) =  1 - prob(~chosen);
prob = prob(:,1);
return

function [prob, value_hard] = prob_para_bias(p,rewardEasy,rewardHard,effort,chosen)
discount = p(1);
beta = p(2);
value_hard = rewardHard - (discount .* effort.^2);
value_easy = rewardEasy;
prob =  exp((beta.*value_hard) + p(3))./(exp(beta.*value_easy) + exp((beta.*value_hard) + p(3)));
prob(~chosen) =  1 - prob(~chosen);
prob = prob(:,1);
return

function [prob, value_hard] = prob_hyp_bias(p,rewardEasy,rewardHard,effort,chosen)
discount = p(1);
beta = p(2);
value_hard = rewardHard ./ ( 1 +(discount .* effort));
value_easy=rewardEasy;
prob =  exp((beta.*value_hard) + p(3))./(exp(beta.*value_easy) + exp((beta.*value_hard) + p(3)));
prob(~chosen) =  1 - prob(~chosen);
prob = prob(:,1);
return

function [prob, value_hard] = prob_exp_bias(p,rewardEasy,rewardHard,effort,chosen)
discount = p(1);
beta = p(2);
value_hard =   rewardHard .*exp(-discount .* effort);
value_easy=rewardEasy;
prob =  exp((beta.*value_hard) + p(3))./(exp(beta.*value_easy) + exp((beta.*value_hard) + p(3)));
prob(~chosen) =  1 - prob(~chosen);
prob = prob(:,1);
return
