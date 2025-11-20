/* 
 * Use historical closing and opening prices for the NASDAQ   * to built an exponentially weighted moving average. 
 *
 * Research into appropriate lamda decay value (.94 or .97)
 *
 * Maybe run simulations to get a more optimal Lamda value 
 */
#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <string>

#include "fileReaderMethods.cpp"
#include "ewmaVolModel.cpp"
 
int main() {
fileReaderMethods myReader;

// reading CSV and storing it
std::vector<std::pair<std::string, std::vector<double>>> data = myReader.read_CSV("openAndCloseData.csv");

//getting the vectors in each pair that have the opening and closing prices respectively
std::vector<double> openingPrices = data[0].second;
std::vector<double> closingPrices = data[1].second;

//constructor to feed Nasdaq Five year daily data
ewmaVolModel myCloseEWMA(closingPrices);
ewmaVolModel myOpenEWMA(openingPrices);

// Calculating log returns + returns squared for EWMA
myCloseEWMA.lnReturn();
myOpenEWMA.lnReturn();

std::cout << "Hello!\nThis little project aims to show the evolution of varience using the EWMA Volatility Model.\nThe project's data comes from historical Nasdaq prices starting at 2020-11-13 and ending at 2025-11-12.\nThe initial varience is set as the average of the first 500 log returns squared.\n" << std::endl;

std::cout << "Starting EWMA Volatility for NASDAQ Close Prices . . . . .\n" << std::endl;
double varienceClose = myCloseEWMA.EWMA();

std::cout << " . . . . . Ending Close Prices EWMA\n" << std::endl;
std::cout << "Starting EWMA Volatility for NASDAQ Open Prices . . . . .\n" << std::endl;

double varienceOpen = myOpenEWMA.EWMA();
std::cout << " . . . . Ending Open Prices EWMA\n" << std::endl;

std::cout << " ========================================== " << "\n" << std::endl;


std::cout << "Ending EWMA using closing prices is: " << varienceClose << "\n" << std::endl;

std::cout << "Ending EWMA using opening prices is: "  << varienceOpen << "\n" << std::endl;



        
        

}