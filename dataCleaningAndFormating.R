#Getting Five Year for VIX and VVIX
library(tidyverse)
library(data.table)

#Load Different Data sets
VixData = VIX_History
VVIXData = VVIX_Historical
NasdaqData = NASDAQFiveYearHistorical
VOOData = VOOHistoricalFiveYear
QQQData = QQQHistoricalFiveYear
DXYData =  DXYHistoricalUpdatedFinal
oilData =   CrushingOKOilPrices
tenUSTre = `10USTreasuryHistorical`
oneUSTre = `1YUSTreasuryData`

# First mutate the date column to fit the format of YYYY-MM-DD using as.Date and format
# Pipe mutated data table into filtering between the two date ranges
VixData = VixData%>% 
          mutate(DATE = as.Date(DATE, 
      #Since our format is MM/DD/YYYY use big Y for format not small y
                        format = "%m/%d/%Y"))%>%
          filter(between(DATE, 
                         as.Date("2020-11-13"),
                         as.Date("2025-11-12")))

#Repeat for VVIX data
VVIXData = VVIXData%>%
            mutate(DATE = as.Date(DATE, format = "%m/%d/%Y" ))%>%
            filter(between(DATE,
                           as.Date("2020-11-13"),
                           as.Date("2025-11-12")))

#Reversing the order of NASDAQ data with respect to date using arrange()
NasdaqData = NasdaqData%>%
  mutate(Date = as.Date(Date, format = "%m/%d/%Y" ))%>%
  filter(between(Date,
                 as.Date("2020-11-13"),
                 as.Date("2025-11-12")))
NasdaqData = NasdaqData%>% arrange(Date)

# Repeat for VOO + Reverse Old --> New
VOOData = VOOData %>% mutate(Date = as.Date(Date, format = "%m/%d/%Y"))%>%
  filter(between(Date, 
                 as.Date("2020-11-13"), 
                 as.Date("2025-11-12")))
VOOData = VOOData %>% arrange(Date)

#Repeat for QQQ + Reverse Old --> New
QQQData = QQQData%>% mutate(Date = as.Date(Date, format = "%m/%d/%Y"))%>%
  filter(between(Date,
                 as.Date("2020-11-13"),
                 as.Date("2025-11-12")))
QQQData = QQQData%>% arrange(Date)

#Repeat for DXY INDEX + Remove Vol. and Change.. columns
DXYData = DXYData %>% mutate(Date = as.Date(Date, format = "%m/%d/%Y"))%>%
  filter(between(Date,
                 as.Date("2020-11-13"),
                 as.Date("2025-11-12")))
DXYData = DXYData %>% select(-Vol., -Change..)
DXYData = DXYData %>% arrange(Date)

#Repeat for Crude Oil Data
oilData = oilData %>% mutate(Date = as.Date(Date, format = "%m/%d/%Y"))%>%
  filter(between(Date,
                 as.Date("2020-11-13"),
                 as.Date("2025-11-12")))
oilData = oilData %>% arrange(Date)
#Repeat for US 10Y Treasury
#Raw data is formated YYYY-MM-DD, so have to use different date format
tenUSTre = tenUSTre[-1, ]
tenUSTre = tenUSTre %>% mutate(V1 = as.Date(V1, format = "%Y-%m-%d"))%>%
  filter(between(V1, 
                 as.Date("2020-11-13"),
                 as.Date("2025-11-12")))
#Repeat for US 1Y Treasury
oneUSTre = oneUSTre %>% mutate(Date = as.Date(Date, format = "%m/%d/%Y"))%>%
  filter(between(Date, 
                 as.Date("2020-11-13"),
                 as.Date("2025-11-12")))

#Rename the date column so that its "Date" for all of them
VixData = VixData %>% rename(Date = DATE)
VVIXData = VVIXData %>% rename(Date = DATE)
tenUSTre = tenUSTre %>% rename(Date = V1, Value = V2)

#Rename Columns to make each one unique
VixData = VixData %>% rename(Vix_Open = OPEN, Vix_High = HIGH, Vix_Low = LOW, Vix_Close = CLOSE)
VVIXData = VVIXData %>% rename(VVIX_Price = VVIX)
NasdaqData = NasdaqData %>% rename(Nasdaq_Open = Open, Nasdaq_Close = Close.Last)
DXYData = DXYData %>% rename(DXY_Price = Price,
                             DXY_Open = Open,
                             DXY_High = High,
                             DXY_Low = Low)
VOOData = VOOData %>% rename(VOO_Close = Close.Last,
                             VOO_Volume = Volume,
                             VOO_Open = Open,
                             VOO_High = High,
                             VOO_Low = Low)
QQQData = QQQData %>% rename(QQQ_Close = Close.Last,
                             QQQ_Volume = Volume,
                             QQQ_Open = Open,
                             QQQ_High = High,
                             QQQ_Low = Low)
tenUSTre = tenUSTre %>% rename(ten_Rate = Value)
oneUSTre = oneUSTre %>% rename(one_Rate = Value)


# Want to make a singular table with all NASDAQ Values/Dates ...
# ... and the corresponding values from the other datasets and their columns

# Let masterTable = Nasdaq

masterTable = NasdaqData

# Use left_join (dataTable, by = "date") to join all corresponding column data from other tables

masterTable = masterTable %>% 
  left_join(VixData, by = "Date")%>%
  left_join(VVIXData, by = "Date")%>%
  left_join(VOOData, by = "Date")%>%
  left_join(QQQData, by = "Date")%>%
  left_join(DXYData, by = "Date")%>%
  left_join(oilData, by = "Date")%>%
  left_join(tenUSTre, by = "Date")%>%
  left_join(oneUSTre, by = "Date")  
  
head(VixData)
head(VVIXData)
head(NasdaqData)
head(oilData)
head(DXYData)
head(VOOData)
head(QQQData)
head(tenUSTre)
head(oneUSTre)

head(masterTable)

# Use fwrite to send data to folder
fwrite(VixData, "C:\\Users\\rohit\\OneDrive\\Desktop\\VolatilityPrediction\\XGVIXFiveYearHistorical.csv")
fwrite(VVIXData, "C:\\Users\\rohit\\OneDrive\\Desktop\\VolatilityPrediction\\XGVVIXFiveYearHistorical.csv")
fwrite(NasdaqData, "C:\\Users\\rohit\\OneDrive\\Desktop\\VolatilityPrediction\\XGNASDAQFiveYearHistorical.csv")
fwrite(VOOData, "C:\\Users\\rohit\\OneDrive\\Desktop\\VolatilityPrediction\\XGVOOFiveYearHistorical.csv")
fwrite(QQQData, "C:\\Users\\rohit\\OneDrive\\Desktop\\VolatilityPrediction\\XGQQQFiveYearHistorical.csv")
fwrite(DXYData, "C:\\Users\\rohit\\OneDrive\\Desktop\\VolatilityPrediction\\XGDXYFiveYearHistorical.csv")
fwrite(oilData, "C:\\Users\\rohit\\OneDrive\\Desktop\\VolatilityPrediction\\XGCrudeOilFiveYearHistorical.csv")
fwrite(tenUSTre, "C:\\Users\\rohit\\OneDrive\\Desktop\\VolatilityPrediction\\XGTenYUSTreasuryHistorical.csv")
fwrite(oneUSTre, "C:\\Users\\rohit\\OneDrive\\Desktop\\VolatilityPrediction\\XGOneYUSTreasuryHistorical.csv")


#Creating lags for Closing prices, High, Low, and Volume by 1. 
masterTable = masterTable %>% arrange(Date) %>%
  mutate (
   Nasdaq_CloseLag = lag(Nasdaq_Close,1),
    VIX_HighLag = lag(Vix_High, 1),
    VIX_LowLag = lag(Vix_Low, 1),
    VIX_CloseLag = lag(Vix_Close,1),
    VVIX_CloseLag = lag(VVIX_Price,1),
    
    VOO_VolumeLag = lag(VOO_Volume, 1),
    VOO_CloseLag = lag(VOO_Close, 1),
    VOO_HighLag = lag(VOO_High, 1),
    VOO_LowLag = lag(VOO_Low,1),
    
    QQQ_VolumeLag = lag(QQQ_Volume,1),
    QQQ_CloseLag = lag(QQQ_Close,1),
    QQQ_HighLag = lag(QQQ_High,1),
    QQQ_LowLag = lag(QQQ_Low,1),
    
    DXY_CloseLag = lag(DXY_Price,1),
    DXY_HighLag = lag(DXY_High,1),
    DXY_LowLag = lag(DXY_Low,1),
    
    CrushingOil_CloseLag = lag(CrushingOil_Price,1),
    
    ten_RateLag = lag(ten_Rate,1),
    one_RateLag = lag(one_Rate,1)
  )
#Remove the colums we lagged now as lag creates seprate columns, not replace them
masterTable = masterTable %>% 
  select(
    -Vix_High,
    -Vix_Low,
    -Vix_Close,
    -VVIX_Price,
    
    -VOO_Close,
    -VOO_High,
    -VOO_Low,
    -VOO_Volume,
    
    -QQQ_Close,
    -QQQ_Volume,
    -QQQ_High,
    -QQQ_Low,
    -QQQ_Volume,
    
    -DXY_Price,
    -DXY_High,
    -DXY_Low,
    
    -CrushingOil_Price,
    
    -ten_Rate,
    -one_Rate
  )

 #We Need to omit NA values from the first row (because we lagged)
 #We need to omit the last row b/c we have missing value for 10&1 US treasury rate
 # Had to explictly say dplyr as data.table also had slice method
masterTable = masterTable%>%dplyr::slice(-1) %>%dplyr::slice(-n())

head(masterTable)
tail(masterTable)

fwrite(masterTable, "C:\\Users\\rohit\\OneDrive\\Desktop\\VolatilityPrediction\\XGAllData.csv")

