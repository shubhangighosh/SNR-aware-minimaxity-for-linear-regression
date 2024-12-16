#!/usr/bin/env Rscript

.libPaths("/burg/stats/users/sg4156/rpackages/")
library('snow')
library('doSNOW')
library('parallel')
library('doParallel')
library('foreach')
library('Matrix')
library('glmnet')
library('dials')
library('gurobi')
library('bestsubset')



args = commandArgs(trailingOnly=TRUE)

if (length(args) < 1) {
  stop("At least one argument must be supplied.", call.=FALSE)
}

params <- readLines(args)
eval(parse(text=params))
enet.lg.grid <- expand.grid(enet.lambda.seq, enet.gamma.seq)
enet.lg.grid1 <- expand.grid(enet.lambda.seq, enet.gamma1.seq)

beta <- rep(0, p)
nonzero.ind <- sample.int(p, size = k)
beta[nonzero.ind] <- rep(tau, k)
sd.x <- sqrt(1/n)

num.iters <- 50


ridge.man <- function(lambda,x,y){
  .libPaths("/burg/stats/users/sg4156/rpackages/")
  ans.1 <- (t(x)%*%x + lambda*diag(p))
  ans.2 <- Matrix::chol2inv(Matrix::chol(ans.1))
  ans.3 <- t(x)%*%y
  ans.4 <- ans.2 %*% ans.3
  ans.4
}

soft.thresholding <- function(u, chi){
  sign(u)*max(0, (abs(u) -chi))
}

enet.mod <- function(lambda, gamma, x, y){
  .libPaths("/burg/stats/users/sg4156/rpackages/")
  enet.pre <- t(x)%*%y
  enet.soft <- sapply(enet.pre, function(u){soft.thresholding(u, lambda)})
  enet.est <- enet.soft*gamma
  sum((enet.est - beta)**2)/sum(beta**2)
}

enet.mod.1 <- function(lambda, gamma, x, y){
  .libPaths("/burg/stats/users/sg4156/rpackages/")
  enet.pre <- t(x)%*%y
  enet.soft <- sapply(enet.pre, function(u){soft.thresholding(u, lambda)})
  enet.est <- enet.soft/(1+gamma)
  sum((enet.est - beta)**2)/sum(beta**2)
}


lasso.errs <- matrix(0, num.iters, length(lasso.lambda.seq))
ridge.errs <- matrix(0, num.iters, length(ridge.lambda.seq))
enet.errs <- array(0, dim=c(num.iters, length(enet.gamma.seq), length(enet.lambda.seq)))
enet.errs1 <- array(0, dim=c(num.iters, length(enet.gamma1.seq), length(enet.lambda.seq)))
bss.errs <- rep(0, num.iters)

cl <- makeCluster(28)
registerDoParallel(cl)

for (i in seq(num.iters)){

  x.iter <- matrix(rnorm(n*p, sd=sd.x), nrow=n)
  z <- rnorm(n, sd = sd.z)
  y.iter <- x.iter %*% beta + z

  lasso.fit <- glmnet(x.iter,y.iter,alpha=1, lambda = lasso.lambda.seq, standardize = FALSE, intercept=FALSE)
  lasso.errs[i,] <- apply((lasso.fit$beta-beta), 2, function(x) {sum(x**2)})/sum(beta**2)
  ridge.fit <- foreach(lambda = ridge.lambda.seq, .combine = 'cbind') %dopar% {
          ridge.man(lambda, x.iter, y.iter)
        }
  ridge.errs[i,] <- apply((ridge.fit-beta), 2, function(x) {sum(x**2)})/sum(beta**2)
  enet.err.iter <- foreach(lambda=enet.lg.grid[,1], gamma=enet.lg.grid[,2], .combine='c') %dopar% {
      enet.mod(lambda, gamma, x.iter, y.iter)
  }
  enet.err.mat.iter <- matrix(as.numeric(enet.err.iter), byrow=TRUE, nrow=length(enet.gamma.seq))
  enet.errs[i,,] <- enet.err.mat.iter

  enet.err1.iter <- foreach(lambda=enet.lg.grid1[,1], gamma=enet.lg.grid1[,2], .combine='c') %dopar% {
      enet.mod.1(lambda, gamma, x.iter, y.iter)
  }
  enet.err.mat1.iter <- matrix(as.numeric(enet.err1.iter), byrow=TRUE, nrow=length(enet.gamma1.seq))
  enet.errs1[i,,] <- enet.err.mat1.iter
    
  
  best.sub <- bestsubset::bs(x.iter,y.iter, k, intercept = FALSE, time.limit=180, params=list(Threads=28))
  cat(best.sub$status)
  best.sub.fit <- coef(best.sub)
  bss.errs[i] <- sum((best.sub.fit -beta)**2)/sum(beta**2)


}


stopCluster(cl)

lasso.err.avg <- apply(lasso.errs, 2, mean)
ridge.err.avg <- apply(ridge.errs, 2, mean)
enet.err.avg <- apply(enet.errs, c(2,3), mean)
enet.err1.avg <- apply(enet.errs1, c(2,3), mean)
renet.err.avg <- apply(renet.errs, c(2,3), mean)
bss.err.avg <- mean(bss.errs)

lasso.err.sd <- apply(lasso.errs, 2, sd)
ridge.err.sd <- apply(ridge.errs, 2, sd)
enet.err.sd <- apply(enet.errs, c(2,3), sd)
enet.err1.sd <- apply(enet.errs1, c(2,3), sd)
renet.err.sd <- apply(renet.errs, c(2,3), sd)
bss.err.sd <- sd(bss.errs)

save.file.name <- paste("err.avg.n.", as.character(n),".p.",as.character(p),".k.",as.character(k),".tau.",as.character(tau),".sd.",as.character(sd.z),sep="")
write.table(as.array(t(lasso.err.avg)),file = paste("lasso.", save.file.name, ".csv", sep=""),sep="," , row.names = FALSE, col.names = FALSE)
write.table(as.array(t(ridge.err.avg)),file = paste("ridge.", save.file.name, ".csv", sep=""),sep="," , row.names = FALSE, col.names = FALSE)
write.table(as.array(enet.err.avg),file = paste("enet.", save.file.name, ".csv", sep=""),sep="," , row.names = FALSE, col.names = FALSE)
write.table(as.array(enet.err1.avg),file = paste("enet1.", save.file.name, ".csv", sep=""),sep="," , row.names = FALSE, col.names = FALSE)
write.table(bss.err.avg,file = paste("bss.", save.file.name, ".csv", sep=""),sep="," , row.names = FALSE, col.names = FALSE)

sd.file.name <- paste("sd.avg.n.", as.character(n),".p.",as.character(p),".k.",as.character(k),".tau.",as.character(tau),".sd.",as.character(sd.z),sep="")
write.table(as.array(t(lasso.err.sd)),file = paste("lasso.", sd.file.name, ".csv", sep=""),sep="," , row.names = FALSE, col.names = FALSE)
write.table(as.array(t(ridge.err.sd)),file = paste("ridge.", sd.file.name, ".csv", sep=""),sep="," , row.names = FALSE, col.names = FALSE)
write.table(as.array(enet.err.sd),file = paste("enet.", sd.file.name, ".csv", sep=""),sep="," , row.names = FALSE, col.names = FALSE)
write.table(as.array(enet.err1.sd),file = paste("enet1.", sd.file.name, ".csv", sep=""),sep="," , row.names = FALSE, col.names = FALSE)
write.table(bss.err.sd,file = paste("bss.", sd.file.name, ".csv", sep=""),sep="," , row.names = FALSE, col.names = FALSE)

