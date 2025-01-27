
# data prep -------------------------------------------------------------------
loan_dataset_boost <- source_dataset
loan_dataset_boost <- dplyr::select(loan_dataset_boost, -x_prop_old_age_pension)

kable(tibble(variables = names(loan_dataset_boost)))

#Analysis on base
summary(loan_dataset_boost)
aggr(loan_dataset_boost)

boxplot(loan_dataset_boost$x_account_balance ~ loan_dataset_boost$y_loan_defaulter)
boxplot(loan_dataset_boost$x_avg_account_balance ~ loan_dataset_boost$y_loan_defaulter)

# sampling ----------------------------------------------------------------------------

SplitDataset <- source_train_test_dataset
data.train_boost <- SplitDataset$data.train
data.test_boost <- SplitDataset$data.test

kable(SplitDataset$event.proportion)

loan_dataset_boost$y_loan_defaulter <- as.factor(loan_dataset_boost$y_loan_defaulter)
data.train_boost$y_loan_defaulter   <- as.factor(data.train_boost$y_loan_defaulter)
data.test_boost$y_loan_defaulter    <- as.factor(data.test_boost$y_loan_defaulter)

data.train_boost <- dplyr::select(data.train_boost, names(loan_dataset_boost))
data.test_boost <- dplyr::select(data.test_boost, names(loan_dataset_boost))

# MODELAGEM DOS DADOS - M?TODOS DE ENSEMBLE

names  <- names(data.train_boost) # saving the name of all vars to put on formula
f_full <- as.formula(paste("y_loan_defaulter ~",
                           paste(names[!names %in% "y_loan_defaulter"], collapse = " + ")))


# fit the decision tree model with boosting--------------------------------------------------

# boost <- boosting(f_full, data= data.train_boost, mfinal = 100,
#                   coeflearn = "Freund",
#                   control = rpart.control(minbucket = 25, maxdepth = 1))
# 
# saveRDS(boost, "./models/boosting.rds")

boost <- readRDS("./models/boosting.rds")

# analysing the error evolution by each interation
plot(errorevol(boost, data.train_boost))

# Analysing var importance on model
var_importance <- boost$importance[order(boost$importance,decreasing = T)]
var_importance
importanceplot(boost)








