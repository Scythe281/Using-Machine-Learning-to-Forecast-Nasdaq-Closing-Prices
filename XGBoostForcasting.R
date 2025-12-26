# Using XGBoost to forecast NASDAQ Closing Price at t+1 day
library(xgboost)
library(tidyverse)
library(ggplot2)
library(zoo)
# Split into train and test data
# Train = any data before 1/01/2025, test, everything afterwards

#Check to see the type of each column, need all to be numeric
sapply(masterTable, class)

# ten_RateLag is character, must fix

masterTable = masterTable %>% mutate(ten_RateLag = as.numeric(ten_RateLag))

#check types again
sapply(masterTable, class)

# Raw prices are hard to predict, lets try log price ratio and apply it for other data values as well
  #Approach: 
      # For price: log (price(t)/price(t-1))
      # For volume: log (volume(t)/20DMA)
      # For Vix: log(Vix(t)/Vix(t-1))
      # For intrest rateL IR(t) - IR(t-1)

masterTable <- masterTable %>% 
  arrange(Date) %>% 
  mutate(
    # Prices and Volatility
    across(
      .cols = c(contains("Open"), contains("Close"), contains("HighLag"), contains("LowLag")),
      .fns = ~log(.x / lag(.x)),
      .names = "{.col}_Stationary" # Changed to _Stationary for consistency
    ),
    
    # Volume
    across(
      .cols = contains("VolumeLag"),
      .fns = ~log(.x / rollmean(lag(.x), k = 20, fill = NA, align = "right")),
      .names = "{.col}_Stationary"
    ), 
    
    # Interest Rates
    across(
      .cols = contains("RateLag"), # Added the 's' to contains
      .fns = ~(.x - lag(.x)),
      .names = "{.col}_Stationary"
    )
  )

trainData = masterTable %>% filter(between(Date,
                                           as.Date("2020-11-16"),
                                           as.Date("2024-12-31")))


testData = masterTable %>% filter(between(Date,
                                          as.Date("2025-01-01"),
                                          as.Date("2025-11-11")))
trainData <- trainData %>% drop_na()
testData <- testData %>% drop_na()

RawNasdaqCloseForTest = testData$Nasdaq_Close


head(trainData)
tail(trainData)

trainData = trainData %>% arrange(Date) %>% select(ends_with("_Stationary"))
testData = testData %>% arrange(Date) %>% select(ends_with("_Stationary"))

head(trainData)
tail(trainData)

#Must take out Y, a target vector of our Nasdaq_closeLogReturn, we are trying to predict form both
#Must make matrix of X, all colums besides Nasdaq_close and Date that we are using to forcast Y
# use as.matrix() to make an matrix

# 1. Define the Labels (Y)
Y_train <- trainData$Nasdaq_Close_Stationary
Y_test  <- testData$Nasdaq_Close_Stationary

# 2. Define the Features (X)
# We take EVERYTHING except the specific column we are trying to predict.
X_train <- trainData %>% 
  select(-Nasdaq_Close_Stationary) %>% 
  as.matrix()

X_test <- testData %>% 
  select(-Nasdaq_Close_Stationary) %>% 
  as.matrix()


#Using cross validation K-fold = 5, to find optimal nrounds

crossValidationModel = xgb.cv(
  
  data = X_train,
  label = Y_train,
  
  nfold = 5, #Split training data into 5, use 80% to train, 20% to test
  
  nrounds = 2500, #Try up to five hundered rounds
  
  eta = .02,
  max_depth = 3,
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
  max_depth = 3, #default, how deep each decision tree should go
  subsample = 0.8, #adds randomness, how much of traning data to use for each tree
  colsample_bytree = 0.8 # how much of each feature to consider for each tree
  )

# make the predictions and store them (remember, this is log returns)

predictions = predict(model, X_test)
head(predictions)

 
# Evaluating model's prediction ability

meanAbsoluteReturn = mean(abs(predictions-Y_test)) #how much predictions are off by on average

rootMeanSquareError = sqrt(mean((predictions-Y_test)^2)) #Gives bigger weight to larger mistakes by model in predicting

# % that model explains of the variance in the data
r_squared <- 1 - (sum((Y_test - predictions)^2) / sum((Y_test - mean(Y_test))^2))
print(paste("For", optimal_nround, " nrounds, the model's results are: "))
print(paste("MAE:", round(meanAbsoluteReturn,3)))
print(paste("RMSE:", round(rootMeanSquareError,3)))
print(paste("R^2%:", round(r_squared,3)*100))

# Hard to get absolute accuracy for price prediction, test to see how well we get the direction of the movement
hit_ratio <- mean(sign(predictions) == sign(Y_test))
print(paste("Directional Accuracy (Hit Ratio):", round(hit_ratio * 100, 2), "%"))

#Since we remove all non-stationary data from our test/train sets, we have to get raw data from masterTable, accounting to drop NA values
test_dates = masterTable %>% 
  filter(between(Date, as.Date("2025-01-01"), as.Date("2025-11-11"))) %>%
  drop_na()

#Lets make a plot of our hit rate where 1 means model and result are in the same direction, -1 means they are in opposite directions
accuracyTable = tibble(
  Date  = test_dates$Date,
  directionalResult = ifelse(sign(predictions) == sign(Y_test), 1, -1)
)

accuracyTable <- accuracyTable %>%
  mutate(status = ifelse(directionalResult == 1, "Hit", "Miss"))

ggplot(data = accuracyTable, 
       aes(x = Date, y = directionalResult)) + 
  # This creates the vertical bars
  geom_segment(aes(x = Date, xend = Date, y = 0, yend = directionalResult, 
                   color = status), size = 0.8) +
  # Adds dots at the ends for better visibility
  geom_point(aes(color = status), size = 1.5) +
  # The "Zero" line for reference
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  # Manually setting the colors to Green and Red
  scale_color_manual(values = c("Hit" = "#228B22", "Miss" = "#CC0000")) +
  # Clean up the Y-axis so it only shows Hit and Miss
  scale_y_continuous(breaks = c(-1, 1), labels = c("Miss (-1)", "Hit (1)")) +
  labs(
    x = "Date",
    y = "Prediction Outcome",
    title = "Nasdaq Directional Accuracy Over Time (2025)",
    subtitle = "Green bars indicate correct direction, Red bars indicate incorrect"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = .5, face = "bold"),
    plot.subtitle = element_text(hjust = .5),
    legend.position = "none" # Legend is redundant since colors are intuitive
  )


closeLagForPredictions = test_dates$Nasdaq_CloseLag
#Converting log returns back to raw prices
convertingPredictions = exp(predictions)*closeLagForPredictions
#Finding the difference between forcast prices and raw prices
errorBetweenRawAndForcast = convertingPredictions - RawNasdaqCloseForTest

#Lets create a new data frame just to plot error and date using tibble

plotTable = tibble(
  Date = test_dates$Date,
  Error = errorBetweenRawAndForcast
  
)

head(errorBetweenRawAndForcast)

# Plotting out the difference between raw prices and forcast prices
ggplot(
  data = plotTable,
  aes(x = Date, y = Error) ) +
    geom_line(color = "blue") +
    geom_point(color = "red", size = .5) +
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
volExplain <- tibble(
  # Pull VIX from test_dates because testData doesn't have the Date column
  Volatility = test_dates$VIX_LowLag, 
  Date = test_dates$Date
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

print(paste("Number of days in test data:", nrow(testData)))
print(paste("Number of predictions made:", length(predictions)))
print(paste("Number of predictions made:", length()))


tail(crossValidationModel$evaluation_log, 20)



