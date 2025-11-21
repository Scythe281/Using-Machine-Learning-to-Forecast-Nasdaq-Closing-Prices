#include <vector>
#include <string>
#include <cmath>
#include <iostream>

class ewmaVolModel {

private:
    
std::vector<double> price;
std::vector<double> logReturn;
std::vector<double> returnSquared;

double initalVariance;
double lamda = .94; 

public: 

ewmaVolModel(std::vector<double> nasdaqPrice) : price(nasdaqPrice){};


// calculates log return of prices, oldest --> newest return
void lnReturn () {
    for (int i = 1; i < price.size(); i++) {
        double priceReturn = price[i]/price[i-1];
        logReturn.push_back(std::log(priceReturn));
    }

    for (int i = 0; i < logReturn.size(); i++) {
        returnSquared.push_back(std::pow(logReturn[i],2));
    }
}

// summing the first 500 squared return values and getting inital varience 
double gettingInitialVariance() {
    double sum = 0;
    for (int i = 0; i < 500; i++) {
        sum += returnSquared[i];
    }
    initalVariance = sum/500;
    return initalVariance;
}

// EWMA model that get final varience (sigma^2(t)) -- start at 500 so as not to overweight initial variance 
double EWMA() {
    double value = gettingInitialVariance();
    for (int i = 500; i < returnSquared.size(); i++) {
        value = lamda*value + (1-lamda)*returnSquared[i];
        if (i % 100 == 0) {
        std::cout << "Today " << i << " day EWMA is: " << value << std::endl;
        }
    }
    return value; 
}
































};

