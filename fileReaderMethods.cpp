#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <string>

class fileReaderMethods {

public:



/* Creating a vector where each element is a pair of the Column Name and Column Values
* vector of <string, vector<int>>
*/
std::vector<std::pair<std::string, std::vector<double>>> read_CSV(std::string fileName) {
    /* Creating the vector of <String ColumnName, Vector columnValues> we will output*/
    std::vector<std::pair<std::string, std::vector<double>>> result;

    /*Creating a input file we will read*/
    std::ifstream myFile(fileName);

    /* Ensuring File is open*/ 
    if(!myFile.is_open()) throw std::runtime_error("Could not open file");

    /* Variable we will use*/
    std::string line, colName;
    double val;
    
    /* Reading Column Names and saving them */

    if(myFile.good()) {
        
        /* Getting first Line*/
        std::getline(myFile, line);

        std::stringstream ss(line);

        /* Extracting each Column Name*/
       while(std::getline(ss, colName, ',')){
        /* Making <Column Name, vector<int>> */
        result.push_back({colName, std::vector<double> {}});
       } 
       }
        // Read data, line by line
    while(std::getline(myFile, line))
    {
        // Create a stringstream of the current line
        std::stringstream ss(line);
        
        // Keep track of the current column index
        int colIdx = 0;
        
        // Extract each integer
        while(ss >> val){
            
            // Add the current integer to the 'colIdx' column's values vector
            result.at(colIdx).second.push_back(val);
            
            // If the next token is a comma, ignore it and move on
            if(ss.peek() == ',') ss.ignore();
            
            // Increment the column index
            colIdx++;
        }
    }

    // Close file
    myFile.close();

    return result;

    }














};