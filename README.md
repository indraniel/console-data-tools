Console Data Tools
==================

These are some hacky scripts for doing quick and easy data analysis.
It would probably be more suitable to use a tool such as [R][R],
[NumPy][NumPy]/[SciPy][SciPy], [PDL][PDL], or something similar. But,
who always has the patience to formally clean up and import the data
into these tools when presented with an exciting new and unknown data
set? These scripts are meant for quick gratification.

The tools all receive data by either piping (typically downstream of
standard tools like `awk`, `sed`, `cut`, `perl`, etc.), or from a raw
file consisting of a single column of numbers. Non-numeric data is
skipped.

There are similar tools like these or better created by others on
github. These were simply developed for my own edification.

*These scripts are some of my earliest explorations with Ruby. There are
probably non-idiomatic expressions and approaches galore throughout the
code.*


Scripts
=======

`summary.rb`
------------

* Display basic stats on a data set: min, max, mean, variance, skew,
  kurtosis, quantiles

    Usage: summary [options]
        -t, --tiles x,y,z                list tiles of interest (default: "0.25,0.5,0.75")
        -e, --exact                      Calculate exact quantiles

* The script was designed to work on very large datasets, where the data
  may not be able to reside all in memory. The quantile calculations are
  estimated using an algorithm described in the following paper, ["The P^2
  Algorithm for Dynamic Calculation of Quantiles and Histograms Without
  Storing Observations"][p2-algorithm]. This approach was inspired by
  [LiveStats by Sean Cassidy on bitbucket][livestats].

* Use the `--exact` option on a small dataset, where memory usage is not
  a concern. It will calculate the exact quantile informaion by storing
  all the data points in memory.

* By default the `--exact` is not applied

### Examples ###

    $ perl -le 'srand(10); for (1..100000) { print 0.5 * sqrt(-2*log(rand()))*cos(6.2831853*rand()) }' |./summary.rb
    # records  :     100000
    Min        :  -1.989885
    Max        :   2.300768
    mean       :  -0.000290
    variance   :   0.249514
    skew       :   0.000000
    kurtosis   :  -3.000000
    Est. quantile (0.25) :  -0.338914
    Est. quantile (0.5) :  -0.000075
    Est. quantile (0.75) :   0.335706

    $ perl -le 'srand(10); for (1..100000) { print 0.5 * sqrt(-2*log(rand()))*cos(6.2831853*rand()) }' |./summary.rb -e
    # records  :     100000
    Min        :  -1.989885
    Max        :   2.300768
    mean       :  -0.000290
    variance   :   0.249514
    skew       :   0.000000
    kurtosis   :  -3.000000
    quantile (0.25) :  -0.339077
    quantile (0.5) :  -0.000046
    quantile (0.75) :   0.335420

Notice that the estimated quantiles differ from true quantiles by less than 1%.

`hist.rb`
---------

* Display a histogram.

    Usage: hist [options]
        -s, --step STEPSIZE              set the bin width (default=1.0)
        -f, --full                       Show the full histogram range
        -c, --columns COLUMNS            max width of histogram (default=80)
        -h, --help                       show the help menu

### Example ###

    $ perl -le 'srand(10); for (1..10000) { print 0.5 * sqrt(-2*log(rand()))*cos(6.2831853*rand()) }' |./hist.rb -s 0.1 -c 50
    -1.800 |      1 |
    -1.700 |      1 |
    -1.600 |      1 |
    -1.500 |      7 |
    -1.400 |     16 |
    -1.300 |     15 |
    -1.200 |     32 | *
    -1.100 |     57 | *
    -1.000 |     86 | **
    -0.900 |    143 | ****
    -0.800 |    197 | ******
    -0.700 |    286 | *********
    -0.600 |    345 | ***********
    -0.500 |    442 | **************
    -0.400 |    519 | ****************
    -0.300 |    616 | *******************
    -0.200 |    699 | **********************
    -0.100 |    755 | ************************
     0.000 |   1557 | **************************************************
     0.100 |    817 | **************************
     0.200 |    741 | ***********************
     0.300 |    593 | *******************
     0.400 |    540 | *****************
     0.500 |    404 | ************
     0.600 |    358 | ***********
     0.700 |    250 | ********
     0.800 |    190 | ******
     0.900 |    104 | ***
     1.000 |    101 | ***
     1.100 |     51 | *
     1.200 |     31 |
     1.300 |     14 |
     1.400 |     20 |
     1.500 |      3 |
     1.600 |      6 |
     1.700 |      2 |
    TOTAL  |  10000 |

[R]: http://www.r-project.org
[NumPy]: http://www.numpy.org
[SciPy]: http://www.scipy.org
[PDL]: http://pdl.perl.org
[p2-algorithm]: http://www.cs.wustl.edu/~jain/papers/ftp/psqr.pdf
[livestats]: https://bitbucket.org/scassidy/livestats
