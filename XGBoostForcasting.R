# Using XGBoost to forecast NASDAQ Closing Price at t+1 day

library(xgboost)
library(tidyverse)
library(ggplot2)
# Split into train and test data
# Train = any data before 1/01/2025, test, everything afterwards

# Raw prices are hard to predict, lets try log returns

masterTable = masterTable %>% mutate(Nasdaq_CloseLogReturn = log(Nasdaq_Close/Nasdaq_CloseLag))
head(masterTable)

#Check to see the type of each column, need all to be numeric
sapply(masterTable, class)

# ten_RateLag is character, must fix

masterTable = masterTable %>% mutate(ten_RateLag = as.numeric(ten_RateLag))

#check types again
sapply(masterTable, class)

trainData = masterTable %>% filter(between(Date,
                                           as.Date("2020-11-16"),
                                           as.Date("2024-12-31")))


testData = masterTable %>% filter(between(Date,
                                          as.Date("2025-01-01"),
                                          as.Date("2025-11-11")))
#Must take out Y, a target vector of our Nasdaq_closeLogReturn, we are trying to predict form both
#Must make matrix of X, all colums besides Nasdaq_close and Date that we are using to forcast Y
# use as.matrix() to make an matrix

Y_train = trainData$Nasdaq_CloseLogReturn
X_train = trainData %>% select(-Nasdaq_Close, -Date, -Nasdaq_CloseLogReturn) %>% 
  as.matrix()

RawNasdaqCloseForTest = testData$Nasdaq_Close

Y_test = testData$Nasdaq_CloseLogReturn
X_test = testData %>% select(-Nasdaq_Close, -Date, -Nasdaq_CloseLogReturn) %>%
  as.matrix()

#Using cross validation K-fold = 5, to find optimal nrounds

crossValidationModel = xgb.cv(
  
  data = X_train,
  label = Y_train,
  
  nfold = 15, #Split training data into 15, use 80% to train, 20% to test
  
  nrounds = 2500, #Try up to five hundered rounds
  
  eta = .02,
  max_depth = 6,
  objective = "reg:squarederror",
  
  early_stopping_rounds = 30, #If no improvements for 30 rounds, stop
  
  verbose = 1
  
)

optimal_nround = crossValidationModel$best_iteration



# Build the XGBoost Model 
model = xgboost(
  data = X_train,
  label = Y_train,
  nrounds = optimal_nround, # tells model how many decision trees to build, risk of Overfitting
  objective = "reg:squarederror",#reg = continuous numbers, squarederror = RMSE
  verbose = 1, #How much to show work as model is running
  eta = .02, # Go slower for better accuracy
  max_depth = 6, #default, how deep each decision tree should go
  subsample = 0.8, #adds randomness, how much of traning data to use for each tree
  colsample_bytree = 0.8 # how much of each feature to consider for each tree
  )

# make the predictions and store them (remember, this is log returns)

predictions = predict(model, X_test)

 
# Evaluating model's prediction ability

meanAbsoluteReturn = mean(abs(predictions-Y_test)) #how much predictions are off by on average

rootMeanSquareError = sqrt(mean((predictions-Y_test)^2)) #Gives bigger weight to larger mistakes by model in predicting

# % that model explains of the variance in the data
r_squared <- 1 - (sum((Y_test - predictions)^2) / sum((Y_test - mean(Y_test))^2))
print(paste("For", optimal_nround, " nrounds, the model's results are: "))
print(paste("MAE:", round(meanAbsoluteReturn,3)))
print(paste("RMSE:", round(rootMeanSquareError,3)))
print(paste("R^2%:", round(r_squared,3)*100))

closeLagForPredictions = testData$Nasdaq_CloseLag
#Converting log returns back to raw prices
convertingPredictions = exp(predictions)*closeLagForPredictions
#Finding the difference between forcast prices and raw prices
errorBetweenRawAndForcast = convertingPredictions - RawNasdaqCloseForTest

#Lets create a new data frame just to plot error and date using tibble

plotTable = tibble(
  Date = testData$Date,
  Error = errorBetweenRawAndForcast
  
)

head(errorBetweenRawAndForcast)

# Plotting out the difference between raw prices and forcast prices
ggplot(
  data = plotTable,
  aes(x = Date, y = Error) ) +
    geom_line(color = "blue") +
    geom_point(color = "red") +
    labs(
      x = "Date",
      y = "Prediction Error",
      title = "Forcast Price Minus Raw Price For Nasdaq"
    ) +
    theme(
      plot.title = element_text(hjust = .5)
    )
#Lets see if volatility (VIX) helps to explain our error 
#Keep in mind, because of lag, Vol = t -1
volExplain = tibble(
  Volatility = testData$VIX_LowLag,
  Date = testData$Date
)
# Need scale factor to size VIX and Error properly
scale_factor = max(abs(errorBetweenRawAndForcast))/max(volExplain$Volatility)

ggplot() +
  geom_line(data = plotTable, aes(x = Date, y = Error), color = "blue") +
  geom_point(data = plotTable, aes(x = Date, y = Error), color = "red") +
  geom_line(data = volExplain, aes(x = Date, y = Volatility*scale_factor), color = "black")+
  #geom_point(data = volExplain, aes(x = Date, y = Volatility*scale_factor), color = "grey")+
  labs(
    x = "Date",
    y = "Price",
    title = "Forcast Price Minus Raw Price for Nasdaq & Lagging Volatility"
  ) +
  # Need to build a secondary axis and rescale it back by dividing primary axis by scale_factor
  scale_y_continuous(
    sec.axis = sec_axis(~./scale_factor, name = "Volatility (VIX, 1 day Lag)")
  )+
  theme(
    plot.title = element_text(hjust = .5)
  )



tail(crossValidationModel$evaluation_log, 20)



