import std.stdio;

class dataTrace
{
private:
    double[] time;
    double[] data;
    double mean_;
    bool meanCalculated = false;
    double stdev_;
    bool stdevCalculated = false;
    double slope_;
    bool slopeCalculated = false;
    
    void calcMean()
    {
        import dstats.summary : mean;
        this.mean_ = mean(this.data);
    }

    void calcStdev()
    {
        import dstats.summary : stdev;
        this.stdev_ = stdev(data);
    }

    void calcSlope()
    {
        import dstats.regress: linearRegress;
        import std.range : repeat;
        //perform a linear regression
        auto results = linearRegress(this.data, repeat(1), this.time);
        //get slope from the betas array.
        this.slope_ = results.betas[1];
    }
unittest
{
    import dstats.summary : stdev;
    import dstats.regress;
    auto testTrace = new dataTrace("a",
                                   [1,2,3,4,5,6,7],
                                   [0.6,1.7,3.2,4.0,4.5,5.8,7.2]);
    import std.math;
    //make sure the right mean is calculated
    assert(abs(testTrace.mean - 3.857) < 0.001);
    //make sure the right stdev is calculated
    assert(abs(testTrace.stdev - 2.275) < 0.001);
    //check slope
    assert(abs(testTrace.slope - 1.046) < 0.001);
}
public:
    string name;
    
/** Constructor that takes data arrays directly to make a new data trace
*/
    this(string name, double[] time, double[] data)
    in
    {
        assert(name !is null);
        assert(time !is null && time.length > 2);
        assert(data !is null && data.length > 2);
        assert(time.length == data.length);
    }
    body
    {
        this.name = name;
        this.time = time;
        this.data = data;
    }

    double mean() @property
    {
        if(!meanCalculated)
        {
            calcMean();
            meanCalculated = true;
        }
        return mean_;
    }


    double stdev() @property
    {
        if(!stdevCalculated)
        {
            calcStdev();
            stdevCalculated = true;
        }
        return stdev_;
    }

    double slope() @property
    {
        if(!slopeCalculated)
        {
            calcSlope();
            slopeCalculated = true;
        }
        return slope_;
    }
}

import std.file : FileException;
/** This function will try to read a data trace from a csv file.
    Time is assumed to be in the first column (index 0).
    Params:
        filePath = Path to the csv file to be parsed
        dataColumn = zero-based index of the data column.
    Throws:
        FileException if path cannot be found, anything goes wrong when reading or things don't add up in the file
*/
dataTrace getTraceFromCsv(string filePath, int dataColumn)
in
{
    assert(dataColumn > 0 && dataColumn < 4);
}
body
{
    double[] time, data;
    
    import std.file;
    import std.algorithm;
    import std.csv;
    import std.typecons;
    import std.string : chomp;
    import UCS2File;
    auto dataFile = File(filePath, "r");
    auto rawLines = dataFile.ByUCS2Line;
    auto convertedLines = rawLines.map!(line => cast(wchar[])(line));
    auto commaLessLines = convertedLines.map!(line => chomp(line, ","));
    
    auto filteredLines = commaLessLines.filter!(line => line.length > 0);
    auto input = filteredLines.joiner("\r\n");
    
    auto records = csvReader!(Tuple!(double, double, double, double))(input, null);
    foreach (record; records)
    {
        time ~= record[0];
        data ~= record[2];
    }
    return new dataTrace("", time, data);
}

string workingDir;
dataTrace[] datasets;

int main(string[] argv)
{
    workingDir = getWorkingDir(argv);
    if (workingDir.length == 0) {return 1;}

    //at this stage, we have found our working directory
    import std.algorithm.mutation : SwapStrategy;
    import std.algorithm.sorting : sort;
    import std.path : buildPath;
    import std.string : toUpper;
    foreach(f; fileList(workingDir, ["csv"])
                .sort!((a, b) => a.toUpper < b.toUpper, SwapStrategy.stable))
    {
        int dataColumn = 3;
        import std.algorithm.searching : canFind;
        if(f.canFind("_O2", "_CO2_2"))
        {
            dataColumn = 2;
        }
        try
        {
            datasets ~= getTraceFromCsv(buildPath(workingDir, f), dataColumn);
        }
        catch(FileException)
        {
            writeln("Could not parse file " ~ buildPath(workingDir, f));
        }
    }

    //write results to file, bluntly overwriting
    auto reportFile = File(buildPath(workingDir, "BGScanEval.tsv"),"w");
    import std.conv : to;
    foreach(dt; datasets)
    {
        reportFile.write(dt.name ~ " mean" ~ '\t');
        reportFile.write(dt.name ~ " stdev" ~ '\t');
        reportFile.write(dt.name ~ " slope" ~ '\t');
    }
    reportFile.writeln();
    foreach(dt; datasets)
    {
        reportFile.write(to!string(dt.mean) ~ '\t');
        reportFile.write(to!string(dt.stdev) ~ '\t');
        reportFile.write(to!string(dt.slope) ~ '\t');
    }
    reportFile.writeln();
    reportFile.close();
    return 0;
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
    //this is a problem when directory is moved/renamed/deleted in the meantime
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