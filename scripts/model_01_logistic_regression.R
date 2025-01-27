# data prep -------------------------------------------------------------------

loan_dataset_logistic <- source_dataset

kable(tibble(variables = names(loan_dataset_logistic)))


# looking for low variability in the dummy variables.

dummy_variables <- dplyr::select(loan_dataset_logistic, 
                                 starts_with('x_client_gender'), 
                                 starts_with('x_district_name'),
                                 starts_with('x_region'),
                                 starts_with('x_card_type'))

dummy_variables_high <- tibble(variables = names(dummy_variables),
       zeros = sapply(dummy_variables, 
                      function(x) table(as.character(x) == 0)["TRUE"]),
       ones = sapply(dummy_variables, 
                     function(x) table(as.character(x) == 1)["TRUE"])) %>% 
  mutate(prop_ones = round(ones / (zeros + ones) * 100, 2)) %>% 
  arrange(prop_ones) %>% 
  filter(prop_ones  > 5)

kable(dummy_variables_high)

dummy_variables_high <- dummy_variables_high$variables
dummy_variables_low <- names(dplyr::select(dummy_variables, -dummy_variables_high))

loan_dataset_logistic <- dplyr::select(loan_dataset_logistic, -dummy_variables_low)


# looking for low variability in the transaction proportion variables.

prop_variables <- dplyr::select(loan_dataset_logistic, 
                                starts_with('x_prop'))

prop_variables <- summary(prop_variables)

kable(t(prop_variables))

loan_dataset_logistic <- dplyr::select(loan_dataset_logistic, -x_prop_old_age_pension)

# evaluating multicolinearity of remaining variables.
vars.quant <- select_if(loan_dataset_logistic, is.numeric)
VIF <- imcdiag(vars.quant, loan_dataset_logistic$y_loan_defaulter)

VIF_Table_Before <- tibble(variable = names(VIF$idiags[,1]),
                    VIF = VIF$idiags[,1]) %>% 
             arrange(desc(VIF))

knitr::kable(VIF_Table_Before)

# taking multicolinear variables from the dataset via VIF.

low_VIF <- filter(VIF_Table_Before, VIF <= 5)$variable
high_VIF <- filter(VIF_Table_Before, VIF > 5)$variable

high_VIF_dataset <- dplyr::select(loan_dataset_logistic, high_VIF)

cor_mtx_high_VIF <- cor(high_VIF_dataset)

high_VIF_correlogram_before <- ggcorrplot(cor_mtx_high_VIF, 
                                hc.order = TRUE,
                                lab = FALSE,
                                lab_size = 3, 
                                method="square",
                                colors = c("tomato2", "white", "springgreen3"),
                                title="Correlation Matrix of Loan Dataset Variables with high VIF") +
  theme(axis.text = element_blank(),
        legend.position = 0)

print(high_VIF_correlogram_before)

# selecting variables to reject -----------------------------------------------
correl_threshold <- 0.6

reject_variables_vector <- tibble(var_1 = row.names(cor_mtx_high_VIF)) %>% 
  bind_cols(as_tibble(cor_mtx_high_VIF)) %>% 
  melt(id = c("var_1")) %>% 
  filter(var_1 != variable) %>%
  mutate(abs_value = abs(value)) %>%
  filter(abs_value > correl_threshold) %>%
  group_by(var_1) %>% 
  mutate(sum_1 = sum(abs_value)) %>% 
  ungroup() %>% 
  group_by(variable) %>% 
  mutate(sum_2 = sum(abs_value)) %>% 
  ungroup() %>% 
  mutate(reject = ifelse(sum_1 > sum_2, var_1, as.character(variable))) %>% 
  distinct(reject)

reject_variables_vector <- reject_variables_vector$reject

clean_dataset <- dplyr::select(loan_dataset_logistic, -reject_variables_vector)

kable(reject_variables_vector)

# comparing correlograms before and after --------------------------------------
cor_mtx_full <- cor(loan_dataset_logistic)
cor_mtx_clean <- cor(clean_dataset,)

full = ggcorrplot(cor_mtx_full, hc.order = TRUE,
           lab = FALSE, 
           lab_size = 3, 
           method="square", 
           colors = c("tomato2", "white", "springgreen3"),
           title="Correlation Matrix of Full Loan Dataset") +
  theme(axis.text = element_blank(),
        legend.position = 0)

clean = ggcorrplot(cor_mtx_clean, hc.order = TRUE,
           lab = FALSE, 
           lab_size = 3, 
           method="square", 
           colors = c("tomato2", "white", "springgreen3"),
           title="Correlation Matrix of Clean Loan Dataset") +
  theme(axis.text = element_blank(),
        legend.position = 0)

print(ggarrange(full, clean))

loan_dataset_logistic <- clean_dataset

# evaluating multicolinearity of remaining variables ---------------------------
vars.quant <- select_if(loan_dataset_logistic, is.numeric)

VIF <- imcdiag(vars.quant, loan_dataset_logistic$y_loan_defaulter)

VIF_Table_After <- tibble(variable = names(VIF$idiags[,1]),
                          VIF = VIF$idiags[,1]) %>%
  arrange(desc(VIF))

ggplot(VIF_Table_After, aes(x = fct_reorder(variable, VIF), 
                            y = log(VIF), label = round(VIF, 2))) + 
  geom_point(stat='identity', fill="black", size=15)  +
  geom_segment(aes(y = 0, 
                   yend = log(VIF), 
                   xend = variable), 
               color = "black") +
  geom_text(color="white", size=4) +
  geom_hline(aes(yintercept = log(5)), color = 'red', size = 2) +
  scale_y_continuous(labels = NULL, breaks = NULL) +
  coord_flip() +
  theme_economist() +
  theme(legend.position = 'none', 
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank()) +
  labs(x = 'Variable',
       y = NULL,
       title = 'Variance Inflation Factor',
       subtitle="Checking for multicolinearity in X's variables.
       Variables with VIF more than 5 will be droped from the model")

loan_dataset_logistic <- dplyr::select(loan_dataset_logistic, -x_average_salary)

# outliers ----------------------------------------------------------------------------

  attach(loan_dataset_logistic)

  par(mfrow=c(2, 3))

  plot(x_last_transaction_age_days, main = "x_last_transaction_age_days", ylab = '')
  plot(x_avg_account_balance, main = "x_avg_account_balance", ylab = '')
  plot(x_account_balance, main = "x_account_balance", ylab = '')
  plot(x_card_age_month, main = "x_card_age_month", ylab = '')
  plot(x_client_age, main = "x_client_age", ylab = '')
  plot(x_loan_amount, main = "x_loan_amount", ylab = '')
  
  par(mfrow=c(2, 3))
  
  plot(x_loan_duration, main = "x_loan_duration", ylab = '')
  plot(x_loan_payments, main = "x_loan_payments", ylab = '')
  plot(x_prop_interest_credited, main = "x_prop_interest_credited", ylab = '')
  plot(x_prop_loan_payment, main = "x_prop_loan_payment", ylab = '')
  plot(x_prop_statement, main = "x_prop_statement", ylab = '')
  plot(x_prop_insurance_payment, main = "x_prop_insurance_payment", ylab = '')

  detach(loan_dataset_logistic)

# sampling ----------------------------------------------------------------------------

SplitDataset <- source_train_test_dataset
data.train_logistic <- SplitDataset$data.train
data.test_logistic <- SplitDataset$data.test

data.train_logistic <- dplyr::select(data.train_logistic, names(loan_dataset_logistic))
data.test_logistic <- dplyr::select(data.test_logistic, names(loan_dataset_logistic))

kable(SplitDataset$event.proportion)

# fit the logistic model -------------------------------------------------------------

# run model
# logistic.full <- glm(formula = y_loan_defaulter ~ .,
#                      data= data.train_logistic, 
#                      family= binomial(link='logit'))
# 
# names(logistic.full$coefficients) <- stringr::str_sub(names(logistic.full$coefficients), 1, 25)
# summary(logistic.full)

# # save model
# saveRDS(logistic.full, './models/logistic_full.rds')

# load model
logistic.full <- readRDS('./models/logistic_full.rds')

# # run model
# logistic.step <- step(logistic.full, direction = "both", test = "F")
# 
# names(logistic.step$coefficients) <- stringr::str_sub(names(logistic.step$coefficients), 1, 25)
# summary(logistic.step)
# 
# # save model
# saveRDS(logistic.step, './models/logistic_step.rds')

# load model
logistic.step <- readRDS('./models/logistic_step.rds')
