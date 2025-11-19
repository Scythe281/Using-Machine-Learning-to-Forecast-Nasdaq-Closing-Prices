**Introduction**
Hello! 

This project was my first attempt to forcast Nasdaq closing prices for a bigger project I have planed to get a 95% confidence interval range for tomorrows Nasdaq's closing prices. That other project is building a Equal Weighted Moving Average Volatility to get a sense of the next day's volaitility. Combining them both, I hope to create a 95% confidence interval for tomorrows Nasdaq's Closing prices. 

**Files Explained** 

The first file in this project was is the dataCleaningAndFormating.R file where I cleaned up the various data tables, standardized their date format, changed their column names, added lags, and took other crucial steps to create a data table that joined the various data files. 

After that, I built the XGBoostForcasting.R file where I further cleaned the final table I was going to work with, wrote an algorithm to find the optimal nrounds, and finally built the XGBoost model. I tweaked around with certain hyperparameters but most of the hyperparameters I kept as their deafult values. In this file, I also created some graphs. The first graph shows my model's error -- the difference between the predicted price and actual price over the test data set -- while the second over laps the first graph with one day lagging VIX values. 

**Conclusion** 
Building this project has taught me a lot -- data cleaning, data wrangling, machine learning, hyperparameters, and more. I also got to find out emperically just how noisy daily stock data is. Even so, I am in the process of building a better model where I try to make more of my data stationary -- or, rather, run tests to see if they can be classified as stationary before. But, I wanted to upload this project as refrence and give out the data that I worked with. 
