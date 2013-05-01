#!/usr/bin/env ruby

# For skewness and kurtosis calculations:
# http://www.itl.nist.gov/div898/handbook/eda/section3/eda35b.htm

require 'optparse'

module ConsoleTools
  class EstimatedQuantile
    # This class is designed to work for large numerical datasets.
    #
    # Class instances estimate a given quantile by calculating them
    # dynamically as data points are observed, via a set of 5 statistical
    # counters. IT DOES NOT STORE ANY OF THE OBSERVATIONS.
    #
    # It is based upon the following paper
    # "The P^2 Algorithm for Dynamic Calculation of Quantiles and Histograms
    #  Without Storing Observations"
    # see http://www.cs.wustl.edu/~jain/papers/ftp/psqr.pdf
    attr_accessor :quantile, :desired_positions, :positions, :heights, :startup,
                  :delta_positions

    def initialize(quantile=0.5)
      @quantile  = quantile
      @heights   = Array.new
      @positions = (1..5).to_a
      @desired_positions = [1, 1 + 2*quantile, 1 + 4*quantile, 3 + 2*quantile, 5]
      @delta_positions = [0, quantile/2, quantile, (1 + quantile)/2, 1]
      @startup   = false
    end

    def record(data)
      # collect the 1st 5 observations
      if @heights.length != 5
        @heights.push(data)
        return 1
      end

      # sort the 1st 5 observations
      # (only for the first time we get to this section of code)
      if @startup == false
        @heights.sort!
        @startup = true
      end

      k = 0

      # data observation is the lowest thing seen so far
      if data < @heights[0]
        @heights[0] = data
        k = 1

      # check if data observation is in the range of middle three markers
      else
        (1...@heights.length).to_a.each do |i|
          if @heights[i-1] <= data && data < @heights[i]
            k = i
            break
          end
        end
      end

      # if the data observation is the highest thing seen so far
      if k == 0 
        k = 4
        @heights[-1] = data if @heights[-1] < data
      end

      # increment all the positions 

    end

    def p2(qp1, q, qm1, d, np1, n, nm1)
      c1 = d / (np1 - nm1)
      c2 = (n - nm1 + d) * (qp1 - q) / (np1 - n)
      c3 = (np1 - n - d) * (q - qm1) / (n - nm1)

      q_new = q + c1 * (c2 + c3)
      return q_new
    end

    def quantile
    end

    private
    def adjust_markers
    end

  end

  class SummaryStats
    attr_accessor :count, :min, :max, :mean, :variance, :kurtosis, :skew, :quantiles

    def initialize(quantiles=[0.5])
      @min      = (2**(0.size * 8 -2) -1)  # ruby system FIXNUM_MAX
      @max      = -(2**(0.size * 8 -2))    # ruby system FIXNUM_MIN
      @count    = 0
      @mean     = 0.0
      @variance = 0.0
      @skew     = 0.0
      @kurtosis = 0.0
    end

    def record(data)
      delta = data - @mean

      @count += 1

      @min = data < @min ? data : @min
      @max = data > @max ? data : @max

      # Sample average / mean
      @mean = (@count * @mean + data) / (@count + 1)

      # Sample variance (except for the scaling term)
      @variance = @variance + delta * (data - @mean)

      # Sample kurtosis (except for the scaling term)
      @kurtosis = @kurtosis = (data - @mean)**4.0

      # Sample skewness (except for the scaling term)
      @skew = @skew + (data - @mean)**3.0
    end

    def show
      puts "%-10s : %10d" % ["# records", @count]
      puts "%-10s : %10f" % ["Min", @min]
      puts "%-10s : %10f" % ["Max", @max]
      puts "%-10s : %10f" % ["mean", @mean]
      puts "%-10s : %10f" % ["variance", self.sample_variance]
      puts "%-10s : %10f" % ["skew", self.sample_skew]
      puts "%-10s : %10f" % ["kurtosis", self.sample_kurtosis]
    end

    def sample_variance
      return @variance / (@count - 1)
    end

    def sample_kurtosis
      return (@kurtosis / (@count * @variance**2.0)) - 3.0
    end

    def sample_skew
      return @skew / (@count * @variance**1.5)
    end

  end
end

if __FILE__ == $0
  options = {}

  optparse = OptionParser.new do |opts|
    options[:tiles] = [0.25, 0.5, 0.75]
    description = 'list tiles of interest (default: "0.25,0.5,0.75")'
    opts.on('-t', '--tiles x,y,z', Array, description) do |list|
      list.map! { |i| i.to_f }
      options[:tiles] = list 
    end
  end

  optparse.parse!

  h = ConsoleTools::SummaryStats.new(quantiles=options[:tiles])

  ARGF.each_line do |e|
    data = e.strip.to_s
    next if data.empty?
    data = data.to_f
    h.record(data)
  end

  h.show
end