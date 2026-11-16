# Mixed effects logistic regression of the direct comparison choices
# (ignore vs update) with performance (deviance) as predictor.
# Input: choicesRDir.csv (CW_analysis.m step 4) and MedianAcc.csv (step 2).
# Output: mod4_<prefix>Direct.RData, mod5_<prefix>Direct.RData
rm(list=ls())

library(lme4)
library(reshape2)

# project folder = parent of the folder that contains this script
get_script_dir <- function() {
  file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(file_arg)) return(dirname(normalizePath(sub("^--file=", "", file_arg))))  # Rscript
  for (i in rev(seq_len(sys.nframe()))) {                                              # source()
    f <- sys.frame(i)$ofile
    if (!is.null(f)) return(dirname(normalizePath(f)))
  }
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())    # RStudio
    return(dirname(rstudioapi::getSourceEditorContext()$path))
  getwd()
}
projectDir <- dirname(get_script_dir())

## Directories
results_dir <- file.path(projectDir, 'derivatives')
exp1 <- file.path(results_dir, 'Experiment1')
exp2 <- file.path(results_dir, 'Experiment2')
pool_dir <- file.path(results_dir,'Pooled')

# experiment =1 for original study, 2 for replication and 3 for both studies pooled
experiment=3

if (experiment==2) {
  directory=file.path(exp2, "COGED", "choicesRDir.csv")
  directoryDev=file.path(exp2, "Colorwheel", "MedianAcc.csv")
  directoryOut=dirname(directory)
  prefix='rep'
}else if (experiment==1) {
  directory=file.path(exp1, "COGED", "choicesRDir.csv")
  directoryDev=file.path(exp1, "Colorwheel", "MedianAcc.csv")
  directoryOut=dirname(directory)
  prefix='ori'
}else if (experiment==3) {
  directoryDev=file.path(pool_dir, "MedianAcc.csv")
  directory1= file.path(exp1, "COGED", "choicesRDir.csv")
  directory2= file.path(exp2, "COGED", "choicesRDir.csv")
  directoryOut=dirname(directoryDev)
  prefix='all'
}


################## logistic regression model: No Redo data

if (experiment==3) {
  #read data from both experiments
  IPData1=read.csv(file=directory1,header=F,sep=',')
  IPData2=read.csv(file=directory2,header=F,sep=',')
  #add 100 to subjects IDs from experiment 1 to avoid matching IDs
  IPData1$V1=IPData1$V1+100
  IPData=rbind(IPData2, IPData1)
}else {
  IPData=read.csv(file=directory,header=F,sep=',')
}

names(IPData)=c("participant","condition","setSize","easyOffer","choice","rt","block","button","version")


###performance data
devD=read.csv(file=directoryDev,header=T,sep=',') #deviance accuracy


#convert performance to long format

devLong=reshape(devD,varying =c( "I1","I2","I3","I4","U1","U2","U3","U4"),direction = "long",idvar = "subNo",timevar="setSize",sep="")
deviance=reshape2:::melt.data.frame(devLong,id.vars=c('subNo','setSize'),value.name="deviance",variable.name="condition",measure.vars=c("I","U"))

#replace no answer with NA in choice data
IPData$choice[IPData$choice==9]=NA
IPData$dev=NA


#assign ignore minus update deviance per cell 
for (val in unique(IPData$participant)){
  for (val2 in unique(IPData$setSize)){
    IPData$dev[IPData$participant==val & IPData$setSize==val2]=deviance$deviance[deviance$subNo==val & deviance$condition=="I" & deviance$setSize==val2 ]-deviance$deviance[deviance$subNo==val & deviance$condition=="U" & deviance$setSize==val2 ]

  }}

IPData$condition=as.factor(IPData$condition)

#remove outlier (did not perform choice task) from experiment 2
if (experiment!=1){
  IPDataF=IPData[!IPData$participant %in%c(46,30),  ]
}else{ 
  IPDataF=IPData}

mod4=glmer(choice~setSize+easyOffer+(1+easyOffer+setSize|participant),data=IPDataF,family=binomial,control = glmerControl(optimizer ="bobyqa", optCtrl = list(maxfun=1e+9)))
summary(mod4)
save("mod4", file = sprintf("%s/mod4_%sDirect.RData",directoryOut,prefix))


mod5=glmer(choice~setSize+easyOffer+dev+(1+easyOffer+setSize|participant),data=IPDataF,family=binomial,control = glmerControl(optimizer ="bobyqa", optCtrl = list(maxfun=1e+9)))
summary(mod5)
save("mod5", file = sprintf("%s/mod5_%sDirect.RData",directoryOut,prefix))




findBetas <- function(modelName) {
  Vcov <- vcov(modelName, useScale = FALSE)
  betas <- fixef(modelName)
  se <- sqrt(diag(Vcov))
  zval <- betas / se
  pval <- 2 * pnorm(abs(zval), lower.tail = FALSE)
  pval<-round(pval,digits=6)
  return(cbind(betas, se, zval, pval))}

#compare model with and without deviance (performance index)
anova(mod4,mod5)
#assess presence of condition effect after including deviance

