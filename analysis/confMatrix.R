confMatrix <- function (data){ 
  
data$observed <- colnames(data)
mod_limits <- rev(c('linear', 'parabolic','hyperbolic','exponential','linear_bias','parabolic_bias','hyperbolic_bias','exponential_bias'))
mod_names <- rev(c('linear', 'parabolic','hyperbolic','exponential','linear+bias','parabolic+bias','hyperbolic+bias','exponential+bias'))

data_l <- data %>%
  pivot_longer( !observed, names_to = "expected", values_to = "Probability")

plotName = ggplot(data_l, aes(expected,observed, fill= Probability)) +
  geom_tile() +# geom_text(aes(label=Freq)) +
  scale_fill_gradient(low="white", high="#009194") +
  labs(x = "True model",y = "Model attribution") + 
  theme(text = element_text(size = 13))+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
  scale_x_discrete(labels=mod_names, limits = mod_limits) +
  scale_y_discrete(labels=mod_names,limits= mod_limits)

return(plotName)}