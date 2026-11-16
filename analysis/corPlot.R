corPlot <- function (data){ 
  
plotName <- ggscatter(data, y = 'sim_kappa',x = 'fit_kappa', color = "grey",alpha = 0.3, fill = "light grey",
                 shape = 19, size = 2,
                 add = "reg.line", conf.int = TRUE,  add.params = list(color = "blue",
                                                                       fill = "grey",alpha = 0.4),
                 cor.coef = TRUE, cor.method = "pearson", col= 'red',# label.x = 0.2, label.y = 0.8,
                 ylab = "Simulated", xlab = "Fitted")

return (plotName)}