function [precision,bias]=precisionCW(data,io)
%%% function that calculates precision and bias of responses in the
%%% colorwheel working memory task, using the JV10 toolbox (Bays, Catalao &
%%% Husain, 2009, Journal of Vision; files in analysis/jv10).
%%% Input: data: trial-wise matrix of colorwheel performance, output of
%%% performanceTrialWise.m (type 1). io: analysis parameters defined in
%%% main script CW_analysis.m, including directory paths, IDs (subNo) and
%%% saveD (save data or not).
%%% Output: precision and bias per participant (rows, in the order of
%%% io.subNo) for the columns: I U I1 I2 I3 I4 U1 U2 U3 U4 (condition, and
%%% condition x set size). Precision and bias are calculated relative to
%%% the target colour (precision.csv, precisionBias.csv) and, as a control,
%%% relative to the lure colour (precisionLure.csv, precisionLureBias.csv).

addpath(fullfile(io.analysisDir,'jv10'))
subNr=io.subNo;

% remove trials without a response
data=data(~isnan(data(:,2)),:);
subNo=data(:,1);sz=data(:,4);cond=data(:,5);
degreesCorrect=data(:,8);degreesClick=data(:,9);degreesLure=data(:,10);

[precision,bias]=precisionPerCell(degreesClick,degreesCorrect,subNo,cond,sz,subNr);
[precisionLure,biasLure]=precisionPerCell(degreesClick,degreesLure,subNo,cond,sz,subNr);

if io.saveD
    names={'subNo' 'I' 'U' 'I1' 'I2' 'I3' 'I4' 'U1' 'U2' 'U3' 'U4'};
    writeMatrix(fullfile(io.resultsDir,'precision.csv'),names,[subNr' precision])
    writeMatrix(fullfile(io.resultsDir,'precisionBias.csv'),names,[subNr' bias])
    writeMatrix(fullfile(io.resultsDir,'precisionLure.csv'),names,[subNr' precisionLure])
    writeMatrix(fullfile(io.resultsDir,'precisionLureBias.csv'),names,[subNr' biasLure])
end
end

function [precision,bias]=precisionPerCell(degreesClick,degreesTarget,subNo,cond,sz,subNr)
% precision and bias for ignore (cond 0) and update (cond 2), overall and
% per set size
conds=[0 2];
setSizes=1:4;
precision=nan(length(subNr),2+length(conds)*length(setSizes));
bias=precision;

for s=1:length(subNr)
    col=1;
    % per condition
    for c=conds
        sel=subNo==subNr(s) & cond==c;
        [precision(s,col),bias(s,col)]=precisionBias(degreesClick(sel),degreesTarget(sel));
        col=col+1;
    end
    % per condition and set size
    for c=conds
        for z=setSizes
            sel=subNo==subNr(s) & cond==c & sz==z;
            [precision(s,col),bias(s,col)]=precisionBias(degreesClick(sel),degreesTarget(sel));
            col=col+1;
        end
    end
end
end

function [P,B]=precisionBias(degreesClick,degreesTarget)
% convert to radians in the range [-pi, pi): X is the response, T the target
X=wrap(deg2rad(degreesClick));
T=wrap(deg2rad(degreesTarget));
[P,B]=JV10_error(X,T);
end

function writeMatrix(filename,names,values)
writetable(cell2table([names;num2cell(values)]),filename,'writevariablenames',0)
end
