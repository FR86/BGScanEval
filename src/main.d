import std.stdio;

import dstats.summary;
import dstats.regress;

int main(string[] argv)
{
    return 1;
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
}