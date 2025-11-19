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

ewmaVolModel myEWMA(closingPrices);

double varienceT = myEWMA.EWMA();



        
        

}





















