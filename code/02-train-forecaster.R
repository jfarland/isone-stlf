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
library("plyr")

library("date")
library("lattice")
library("forecast")
library("nlme")
library("mgcv")
library("lfe")
library("SemiPar")

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

#create calendar variables

LFVars <- function()


trn <- subset(dat, year<=2011)
tst <- subset(dat, year>2011)

trn <- lag(trn$load, k=24)

trn0 <- data.frame(trn)



"""
train model
"""
fit1 <- spm(trn$load ~ f(trn$temp) + f(trn$hum) + trn$ws + trn$cc +factor(month)+factor(year)+, group=trn$hour, family = "gaussian",
              spar.method = "REML", omit.missing=NULL)

summary(fit1)
plot(fit1$fitted)
tstDF <- 
fcst <- predict(fit1, newdata=tst, se=TRUE)
