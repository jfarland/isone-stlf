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

for (i in 1 : length(displacements))
{
  disp = displacements[i]
  tst0[,i+cols] <- unlist(shift(tst0$load, -1*disp))
  colnames(tst0)[c(i+cols)] = lagnames[i]
}

"""
train model
"""

fit1 <- lme(load ~ factor(month) + factor(year) + factor(day) + factor(hour) + lag24 +lag48 +lag72 +lag96 +lag120 +lag144 + lag168, data = trn0, random = temp + hum + ws + cc, na.action = na.exclude)

#another amazing reference: http://www.public.iastate.edu/~dnett/S511/
fit1 <- spm(trn0$load ~  f(trn0$temp, basis="trunc.poly",degree=2)+f(trn0$hum, basis="trunc.poly",degree=2)+ factor(trn0$month) + trn0$lag24 +trn0$lag48 +trn0$lag72 +trn0$lag96 +trn0$lag120 +trn0$lag144 + trn0$lag168, group=trn$hour, family = "gaussian",
              spar.method = "REML", omit.missing=TRUE)

#Simon Wood's R Package is much more robust than Matt Wand's.
# Reference ---> http://people.bath.ac.uk/sw283/mgcv/tampere/mgcv.pdf
fit1 <- gam(load ~  s(temp, bs="ps",k=22)+s(hum, bs="ps",k=22)+ s(cc, bs="cp")+ s(ws, bs="cp")+factor(month) + factor(hour) + lag24 +lag48 +lag72 +lag96 + lag120 + lag144 + lag168, family = "gaussian", data = trn0,
            method = "REML", na.action=na.omit)

fit2 <- gam(load ~  s(temp, bs="cp",k=22)+s(hum, bs="cp",k=22)+ s(cc, bs="cp")+ s(ws, bs="cp")+factor(month) + factor(hour) + lag24 +lag48 +lag72 +lag96 + lag120 + lag144 + lag168, family = "gaussian", data = trn0,
            method = "REML", na.action=na.omit)

fit3 <- gam(load ~  s(temp, bs="cp",k=22)+s(hum, bs="cp",k=22)+ s(cc, bs="cp")+ s(ws, bs="cp")+factor(month) + factor(hour) + lag24 +lag48 +lag72 +lag96 + lag120 + lag144 + lag168, family = "gaussian", data = trn0,
            method = "REML", na.action=na.omit)

gam.check(fit1)
plot(fitted(fit1), residuals(fit1))
summary(fit1)
plot(fit1)
anova(fit1)

#out of sample data
fcst<-data.frame(predict(fit1,newdata=tst0))
fcst0<-cbind(tst0$load,fcst)
fcst0["APE"] <- abs((load-fcst)/load)

summary(fcst0)
plot(fcst)

vis.gam(fit1, view=c("temp","hum"),theta=320, thicktype="detailed",)


