import std.stdio;

import dstats.summary;
import dstats.regress;

string workingDir;

int main(string[] argv)
{
    workingDir = getWorkingDir(argv);
    if (workingDir.length == 0) {return 1;}

    //at this stage, we have found our working directory
    return 0;
}

unittest
{
    //fake data
    double[] signal = [0.6,1.7,3.2,4.0,4.5,5.8,7.2];
    //fake time axis
    double[] time = [1,2,3,4,5,6,7];
    //calculate data standard deviation
    double calcSdev = stdev(signal);
    import std.math;
    //make sure the right thing is calculated
    assert(abs(calcSdev - 2.275) < 0.001);
    //perform a linear regression
    auto results = linearRegress(signal, repeat(1), time);
    //check R2
    assert(abs(results.R2 - 0.986) < 0.001);
    //check intercept
    assert(abs(results.betas[0] + 0.328) < 0.001);
    //check slope
    assert(abs(results.betas[1] - 1.046) < 0.001);

    //linear regression with intercept fixed at zero
    results = linearRegress(signal,time);
    assert(abs(results.betas[0] - 0.980) < 0.001);

    //linear regression with defined intercept
    double intercept = 0.5;
    import std.algorithm : map;
    results = linearRegress(map!(a => a + intercept)(signal), time);
    assert(abs(results.betas[0] - 1.080) < 0.001);
}


/**
 * Get a working directory from command line parameters.
 * 
 * Returns: The working directory extracted from the second command line parameter
 * or an empty string if that parameter does not contain anything we can get an existing directory from.
 */
string getWorkingDir(string[] cmdLineParams)
{
    string wd;
    bool existingPathFound = false;
    //check if we have received a path to work with at all,
    //need to have at least 2 cmd line parameters for that
    if (cmdLineParams.length > 1)
    {
        wd = cmdLineParams[1];
        import std.path : isValidPath;
        //check if wd is in principle a valid path
        if (wd.isValidPath)
        {
            import std.file : FileException, isDir;
            try
            {
                //check if wd already points to an existing directory
                if (!wd.isDir)
                {
                    //if this enters (no exception) then we have found an existing file, but not a folder
                    //strip the file off the path
                    import std.path : dirName;
                    wd = wd.dirName;
                }
                existingPathFound = true;
            }
            catch(FileException)
            {
                writeln("boom");
                readln();
                //this is entered when the path is valid but does not point to an existing directory
                //nothing to do here, existingPathFound is false already
            }
        }
    }
    if (!existingPathFound) {wd = "";}
    import std.path : buildNormalizedPath;
    return buildNormalizedPath(wd);
}