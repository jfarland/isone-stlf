"""

Incredible References:
(1) Introduction to GLM's in R - http://statmath.wu.ac.at/courses/heather_turner/glmCourse_001.pdf
(2) Amazing LATTICE Reference -  http://www.isid.ac.in/~deepayan/R-tutorials/labs/04_lattice_lab.pdf
(3) Reference on Stepwise Regression w/GLMs http://data.princeton.edu/R/glms.html

"""

#include packages
library("date")
library("lattice")
library("forecast")
library("XLConnect")
library("gdata")
library("quantreg")
library("corrgram")
library("splines")
library("dplyr")
library("ggplot2")
library("lubridate")

library("date")
library("lattice")
library("forecast")
library("nlme")
library("mgcv")
library("lfe")
library("SemiPar")
library("lubridate")

"""
import data set
"""

dat <- read.csv("~/Documents/Research/projects/isone-stlf/data/REGION.csv")

summary(dat)

"""
visualize data if in interactive mode
"""

hist(dat$load)
pairs(dat)
plot(dat$temp, dat$load)

"""
create function to prepare modeling data set
"""

trn <- subset(dat, year<=2011)
tst <- subset(dat, year>2011)
trn0 <- data.frame(trn)
tst0 <- data.frame(tst)

"""
User Defined Functions
"""

#create a date time variable
toDate <- function(year, month, day) 
  {
  ISOdate(year, month, day)
  }

#create lag and lead variables
#source <- http://ctszkin.com/2012/03/11/generating-a-laglead-variables/
shift<-function(x,shift_by){
  stopifnot(is.numeric(shift_by))
  stopifnot(is.numeric(x))
  
  if (length(shift_by)>1)
    return(sapply(shift_by,shift, x=x))
  
  out<-NULL
  abs_shift_by=abs(shift_by)
  if (shift_by > 0 )
    out<-c(tail(x,-abs_shift_by),rep(NA,abs_shift_by))
  else if (shift_by < 0 )
    out<-c(rep(NA,abs_shift_by), head(x,-abs_shift_by))
  else
    out<-x
  out
}

#date<- ISOdate(trn0$year, trn0$month, trn0$day)


#create lag variables of load
displacements <- seq(24, 168, 24)

#vector of column names
lagnames <- paste("lag", displacements, sep = "")

cols <- dim(trn0)[2] #number of columns before we add lags

for (i in 1 : length(displacements))
{
  disp = displacements[i]
  trn0[,i+cols] <- unlist(shift(trn0$load, -1*disp))
  colnames(trn0)[c(i+cols)] = lagnames[i]
}

"""
train model
"""

fit1 <- lme(load ~ factor(month) + factor(year) + factor(day) + factor(hour) + lag24 +lag48 +lag72 +lag96 +lag120 +lag144 + lag168, data = trn0, random = temp + hum + ws + cc, na.action = na.exclude)


fit1 <- spm(trn0$load ~  f(trn0$temp)+f(trn0$hum)+ factor(trn0$month) + trn0$lag24 +trn0$lag48 +trn0$lag72 +trn0$lag96 +trn0$lag120 +trn0$lag144 + trn0$lag168, group=trn$hour, family = "gaussian",
              spar.method = "REML", omit.missing=TRUE)

summary(fit1)
plot(fit1)
anova(fit1)
fcst <- predict(fit1, newdata=tst0, se=TRUE)
