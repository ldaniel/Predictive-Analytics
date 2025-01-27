# data prep -------------------------------------------------------------------

loan_dataset_DT <-source_dataset
loan_dataset_DT <- dplyr::select(loan_dataset_DT, -x_prop_old_age_pension)

kable(tibble(variables = names(loan_dataset_DT)))

# sampling ----------------------------------------------------------------------------

SplitDataset <- source_train_test_dataset
data.train_DT <- SplitDataset$data.train
data.test_DT <- SplitDataset$data.test

data.train_DT <- dplyr::select(data.train_DT, names(loan_dataset_DT))
data.test_DT <- dplyr::select(data.test_DT, names(loan_dataset_DT))

kable(SplitDataset$event.proportion)

# fit the decision tree model -------------------------------------------------------------

# # run model
# tree.full <- rpart(data= data.train_DT, y_loan_defaulter ~ .,
#                    control = rpart.control(minbucket = 5,
#                                            maxdepth = 5),
#                    method = "class")
# 
# # save model
# saveRDS(tree.full, './models/decision_tree_full.rds')

# load model
tree.full <- readRDS('./models/decision_tree_full.rds')

# plot model
rpart.plot(tree.full, cex = 1.3, type = 0,
           extra = 104, box.palette = 'BuRd',
           branch.lty = 3, shadow.col = 'gray', 
           nn = TRUE, main = 'Decision Tree - Prune')

# prunning
printcp(tree.full)
plotcp(tree.full)

# cp_prune = tree.full$cptable[which.min(tree.full$cptable[,"xerror"]), "CP"]
# tree.prune <- prune(tree.full, cp = cp_prune)
# 
# # save model
# saveRDS(tree.prune, './models/decision_tree_prune.rds')

# load model
tree.prune <- readRDS('./models/decision_tree_prune.rds')

# plot tree
rpart.plot(tree.prune, cex = 1.3, type = 0,
           extra = 104, box.palette = 'BuRd',
           branch.lty = 3, shadow.col = 'gray', 
           nn = TRUE, main = 'Decision Tree - Prune')

printcp(tree.prune)
plotcp(tree.prune)

# feeding full tree back to prune tree
tree.prune <- tree.full
