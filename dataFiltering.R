#Set up tidyverse and data.table library 
library(tidyverse)
library(data.table)

#Import historical data and save it to a data table
myData =  Five_Year_Data_From_Nasdaq

#Filter the Data for Closing and Opening Prices and Both w/Date
newDataSet = myData %>% select(Date, Open, Close.Last)
openAndClose = myData %>% select(Open, Close.Last)

#Use fwrite function to create and export CSV 
fwrite(newDataSet, "C:\\Users\\rohit\\OneDrive\\Desktop\\VolatilityPrediction\\FiveYearData.csv")
fwrite(openAndClose, "C:\\Users\\rohit\\OneDrive\\Desktop\\VolatilityPrediction\\openAndCloseData.csv")


