

library("ISLR")
library("dplyr")
library("ggplot2")
library("lattice")

set.seed(182736352)

names(dat)

km.out <- kmeans(dat$load, 6, nstart=20)

km.out

summary(km.out)
km.out$cluster

plot(dat$load, col=(km.out$cluster+1), cex=2)

dat_cl <- cbind(dat, km.out$cluster)

View(dat_cl)


