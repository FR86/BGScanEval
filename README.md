# BGScanEval
The idea here is to automate evaluation of background scans on IRMS systems.
For now, look at

|Scan time / s| m/z |Cup | file name end (.csv/.dxf)|
|---|---|---|---|
|60|32|2|*_O2|
|300|44|2|*_CO2_2|
|300|44|3|*_CO2_3|
|60|40|3|*_Ar|
|60|18|3|*_H2O|

## Plan
* take folder path as cmd line argument
* get all files with csv extension
  * make sure they are named like we expect
* read in appropriate column using std.csv
* calculate standard deviation of the appropriate column using dstats.summary.stdev (https://github.com/DlangScience/dstats)
* for 44 calculate slope using dstats.regress.linearRegress
  or going with this: https://en.wikipedia.org/wiki/Simple_linear_regression#Fitting_the_regression_line
  or take inspiration from here: http://machinelearningmastery.com/implement-simple-linear-regression-scratch-python

* place results into a text file of appropriate format for copy pasting into confluence table / excel
