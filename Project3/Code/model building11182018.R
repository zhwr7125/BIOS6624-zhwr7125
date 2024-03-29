library(boot)
library(tidyverse)
library(ggplot2)

dat1 <- read.csv("C:/repository/bios6624-zhwr7125/Project3/Code/dat1.csv")
summary(dat1)

factor_vars <- c(1,2,4)
dat1[,factor_vars] <- lapply(dat1[,factor_vars] , factor)




# logistic regression
training <- dat1[dat1$sixmonth != "39",]
m1 <- glm(death30 ~  bmi + asa + proced, data = training,  family = binomial(link=logit))

testing <- dat1[dat1$sixmonth == "39",]
m1_pred <- predict(m1, newdata = testing)

dat1_sub <- dat1[,c(1,2,3,4,7,8,9)]
dat1_sub <- dat1_sub[complete.cases(dat1_sub),]
t_sub <- training[,c(1,2,3,4,7,8,9)]
t_sub <- t_sub[complete.cases(t_sub),]

dat1_sub$t_pred <- predict(m1,newdata = dat1_sub, type = "response")

#get only the 39 period people with complete cases
dat_sub39 <- dat1_sub[dat1_sub$sixmonth == 39,]

#the predicted death rate for each hospital based on the last six months
expected <- data.frame(data.matrix(aggregate(dat_sub39$t_pred,list(dat_sub39$hospcode),mean))*100)

expected 
# parametric method because your repeatedly drawing from the same model, requiring more assumptions on your model
# If we need to bootstrap from predicted values
results1 <- matrix(nrow=44, ncol = 4)
recent <- dat1[dat1$sixmonth == "39" & !is.na(dat1$hospcode),]
means1 <- matrix(nrow = 100, ncol = 3)

predicted <- predict(m1, newdata = hospital, type = "response")

for(i in 1:44){
  hospital <- recent[recent$hospcode == i,]
  predicted <- predict(m1, newdata = hospital, type = "response")
  for(j in 1:100){
    s <- sample(predicted, length(predicted), replace = TRUE)
    means1[j,1] <- round(mean(s, na.rm = T), 4)
    means1[j,2] <- round(quantile(s, .025, na.rm =T), 4)
    means1[j,3] <- round(quantile(s, .975, na.rm =T), 4)
    s <- NULL
  }
  results1[i,2] <- round(mean(means1[,1]), 4)
  results1[i,3] <- round(mean(means1[,2], .025, na.rm = T), 4)
  results1[i,4] <- round(mean(means1[,3], .975, na.rm = T), 4)
  results1[i,1] <- i
  predicted <- NULL
}
colnames(results1) <- c("hospital", "mean_pred", "lower.ci", "upper.ci")
results1 <- as.data.frame(results1)
write.csv(results1, "C:/Repositories/bios6624-zhanglingdi68/Project3//DataProcessed/boot_predicted-11182018.csv")
results1 <- read.csv(file = "C:/Repositories/bios6624-zhanglingdi68/Project3/DataProcessed/boot_predicted-11182018.csv")


# Guannan indicated that our bootstrap should be random sample from historic data repeatedly,
# fit models each time, run predict() each time, and report the mean of the predicted values.
# we then take the mean of the predicted values and compare the current time period's estimate
# to this mean value and see if they differ

# resampling the data is non-parametric because your draw of data is model independent
# runs REAL slo but runs correctly
means <- matrix(nrow = 1000, ncol = 3)
results <- matrix(nrow=44, ncol = 4)
recent <- dat1[dat1$sixmonth == "39" & !is.na(dat1$hospcode),]

for(i in 1:44){
  hospital <- recent[recent$hospcode == i,]
  for(j in 1:1000){
    for(k in 1:44){
      d <- training[training$hospcode == k,]
      f <- sample_n(d, nrow(d), replace = T)
      if(k == 1){all <- f} else(all <- rbind(all, f))
    }

    m_loop <- glm(as.numeric(all$death30) ~ bmi + asa + proced, data = all)
    pred <- predict(m_loop, hospital, type = "response")
    means[j,1] <- round(mean(pred, na.rm = T), 4)
    means[j,2] <- round(quantile(pred, .025, na.rm =T), 4)
    means[j,3] <- round(quantile(pred, .975, na.rm =T), 4)
    s <- NULL
    all <- NULL
  }
  results[i,2] <- round(mean(means[,1]), 4)
  results[i,3] <- round(mean(means[,2], na.rm = T), 4)
  results[i,4] <- round(mean(means[,3], na.rm = T), 4)
  results[i,1] <- i
}  
colnames(results) <- c("hospital", "mean_pred", "lower.ci", "upper.ci")
results <- as.data.frame(results)
results$mean_pred <- results$mean_pred*100
results$lower.ci <- results$lower.ci*100
results$upper.ci <- results$upper.ci*100
beep(2)

write.csv(results, "C:/Repositories/bios6624-zhanglingdi68/Project3/DataProcessed/boot_model-11182018.csv")
results <- read.csv(file = "C:/Repositories/bios6624-zhanglingdi68/Project3/DataProcessed/boot_model-11182018.csv")

# let's plot these CIs to see how much they truly overlap each other

ggplot(results1, aes(x = hospital, y = lower.ci)) + geom_point(color = "lightblue3") +
  geom_point(data = results1, aes(x = hospital, y = upper.ci), color = "lightblue3") + 
  geom_point(data = results, aes(x = hospital, y = lower.ci), color = "coral3") + 
  geom_point(data = results, aes(x = hospital, y = upper.ci), color = "coral3") +
  ggtitle("Lower and Upper CIs by method of Boostrap")

ggplot(results1, aes(hospital, y = mean_pred)) + geom_point(color = "lightblue3") + 
  geom_point(data = results, aes(hospital, mean_pred), color = "coral3") +
  ggtitle("Mean Predicted Rates by Method \nof Bootstrap") + ylab("Mean Predicted")

################ Now for point estimates for each hospital in the current time period

predALL <- predict(m1, newdata = recent, type = "response", se.fit = T)

colnames(results) <- c("hospital", "mean_pred", "lower.ci", "upper.ci")
results <- as.data.frame(results)

##################### lets recreate this without albumin in the model ###############################
means <- matrix(nrow = 150, ncol = 3)
results <- matrix(nrow=44, ncol = 4)
recent <- dat[dat$sixmonth == "39" & !is.na(dat$hospcode),]

for(i in 1:44){
  hospital <- recent[recent$hospcode == i,]
  for(j in 1:150){
    for(k in 1:44){
      d <- training[training$hospcode == k,]
      f <- sample_n(d, nrow(d), replace = T)
      if(k == 1){all <- f} else(all <- rbind(all, f))
    }
    m_loop <- glm(as.numeric(all$death30)~ bmi + asa + proced, data = all)
    pred <- predict(m_loop, hospital, type = "response")
    means[j,1] <- round(mean(pred, na.rm = T), 4)
    means[j,2] <- round(quantile(pred, .025, na.rm =T), 4)
    means[j,3] <- round(quantile(pred, .975, na.rm =T), 4)
    s <- NULL
    all <- NULL
  }
  results[i,2] <- round(mean(means[,1]), 4)
  results[i,3] <- round(mean(means[,2], na.rm = T), 4)
  results[i,4] <- round(mean(means[,3], na.rm = T), 4)
  results[i,1] <- i
}  
colnames(results) <- c("hospital", "mean_pred", "lower.ci", "upper.ci")
results <- as.data.frame(results)
results$mean_pred <- results$mean_pred*100
results$lower.ci <- results$lower.ci*100
results$upper.ci <- results$upper.ci*100
beep(2)

write.csv(results, "C:/Repositories/bios6624-zhanglingdi68/Project3/DataProcessed/boot_model_no_alb.csv")
results <- read.csv(file = "C:/Repositories/bios6624-zhanglingdi68/Project3/DataProcessed/boot_model_no_alb.csv")
