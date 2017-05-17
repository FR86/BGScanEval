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
        import std.path : exists;
        //check if wd is in principle a valid path 
        if (wd.exists)
        {
            existingPathFound = true;
            //check if wd points to a file instead of a directory
            import std.file : isDir;
            if (!wd.isDir)
            {
                //strip the file off the path
                import std.path : dirName;
                wd = wd.dirName;
            }
        }
    }
    if (!existingPathFound) {wd = "";}
    import std.path : buildNormalizedPath;
    return buildNormalizedPath(wd);
}

/**
 * Get a list of files in a directory, optionally filtered by extension.
 * Params:
 *  extensions = Optional array of extensions _without_ preceding dot.
 * Returns: An array of strings representing the found files.
 */
string[] fileList(string pathname, string[] extensions = [])
in
{
    import std.path : exists;
    import std.file : isDir;
    //Right now, I consider the use on a path that hasn't been checked for existence a programming error.
    assert (pathname.exists && pathname.isDir);
    //Using empty extension strings is an error as well
    if(extensions.length > 0)
    {
        foreach (ext; extensions)
        {
            assert(ext.length > 0);
            //Check for max length?
        }
    }
}
body
{
    import std.file;
    import std.path;
    import std.algorithm;
    import std.array;
    
    if (extensions.length == 0)
    {
        //no extensions specified, just give all files in the folder, just this folder
        return std.file.dirEntries(pathname, SpanMode.shallow)
            //make sure what we have is a file
            .filter!(a => a.isFile)
            //get the name of the file off the DirEntry and strip directory
            .map!(a => std.path.baseName(a.name))
            //copy results into new dynamic array
            .array;
    }
    else
    {
        //build a pattern to feed into the filtered version of dirEntries
        string pattern;
        pattern = "*.{";
        foreach(ext; extensions)
        {
            pattern ~= ext ~ ",";
        }
        import std.string;
        //Strip the last comma
        pattern = pattern.chop ~ "}";

        return std.file.dirEntries(pathname, pattern, SpanMode.shallow)
            .filter!(a => a.isFile)
            .map!(a => std.path.baseName(a.name))
            .array;
    }
    

    
}