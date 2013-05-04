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
    attr_accessor :tile, :desired_positions, :positions, :heights, :threshold_flag,
                  :delta_positions

    def initialize(quantile=0.5)
      @tile      = quantile
      @heights   = Array.new
      @positions = (1..5).to_a
      @desired_positions = [1, 1 + 2*quantile, 1 + 4*quantile, 3 + 2*quantile, 5]
      @delta_positions = [0, quantile/2, quantile, (1 + quantile)/2, 1]
      @threshold_flag   = false
    end

    # this is the core algorithm
    def record(data)
      # collect the 1st 5 observations
      if @heights.length != 5
        @heights.push(data)
        return 1
      end

      # sort the 1st 5 observations
      # (only for the first time we get to this section of code)
      if @threshold_flag == false
        @heights.sort!
        @threshold_flag = true
      end

      # Part B1: find the cell interval the new observation resides in
      k = case
          when data < @heights[0]
            # data observation is the lowest thing seen so far
            @heights[0] = data
            0
          when (@heights[0]...@heights[1]).include?(data)
            0
          when (@heights[1]...@heights[2]).include?(data)
            1
          when (@heights[2]...@heights[3]).include?(data)
            2
          when (@heights[3]...@heights[4]).include?(data)
            3
          else
            # if the data observation is the highest thing seen so far
            @heights[4] = data
            3
      end

      # Part B2.a: increment all the positions that are greater than index k
      @positions.each_index do |i|
        @positions[i] += 1 if i > k
      end

      # Part B2.b: increment the desired positions for all markers
      @desired_positions = @desired_positions.
                               zip(@delta_positions).
                               map { |i| i[0] + i[1] }

      # Part B3: adjust marker heights
      1.upto(3) do |i|
        delta = @desired_positions[i] - @positions[i]
        forward_position_delta  = @positions[i+1] - @positions[i]
        backward_position_delta = @positions[i-1] - @positions[i]

        if (delta >= 1 && forward_position_delta > 1) || 
           (delta <= -1 && backward_position_delta < -1)
          sign = delta <=> 0
          new_height = self.quadratic_extrapolation(
            @heights[i+1],
            @heights[i],
            @heights[i-1],
            sign.to_f,
            @positions[i+1].to_f,
            @positions[i].to_f,
            @positions[i-1].to_f
          )

          # linearly interpolate height if the quadratically extrapolated height
          # isn't in the desired range
          if not ( (@heights[i-1]...@heights[i+1]).include?(new_height) )
            new_height = self.linear_extrapolation(
              sign,
              @heights[i],
              @heights[i+sign],
              @positions[i],
              @positions[i+sign],
            )
          end

          @heights[i] = new_height
          @positions[i] = @positions[i] + sign
        end
      end
    end

    def linear_extrapolation(d, q, qd, n, nd)
      c1 = qd - q
      c2 = nd - n
      q_new = q + d * (c1/c2)
      return q_new
    end

    def quadratic_extrapolation(qp1, q, qm1, d, np1, n, nm1)
      c1 = d / (np1 - nm1)
      c2 = (n - nm1 + d) * (qp1 - q) / (np1 - n)
      c3 = (np1 - n - d) * (q - qm1) / (n - nm1)

      q_new = q + c1 * (c2 + c3)
      return q_new
    end

    def quantile
      # this center element is the approximate quantile of interest
      q = @threshold_flag ? @heights[2] : 0
      return q
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
      @quantiles = quantiles.map {|i| ConsoleTools::EstimatedQuantile.new(i)}
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

      @quantiles.each { |q| q.record(data) }
    end

    def show
      puts "%-10s : %10d" % ["# records", @count]
      puts "%-10s : %10f" % ["Min", @min]
      puts "%-10s : %10f" % ["Max", @max]
      puts "%-10s : %10f" % ["mean", @mean]
      puts "%-10s : %10f" % ["variance", self.sample_variance]
      puts "%-10s : %10f" % ["skew", self.sample_skew]
      puts "%-10s : %10f" % ["kurtosis", self.sample_kurtosis]

      @quantiles.each do |q|
        puts "%-10s : %10f" % ["quantile (#{q.tile})", q.quantile]
      end
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

  storage = Array.new
  ARGF.each_line do |e|
    data = e.strip.to_s
    next if data.empty?
    data = data.to_f
    h.record(data)
    storage << data
  end

  h.show

  storage.sort!
  theoretical_median = storage[ (storage.length * 0.5).to_i  ]
  theoretical_top    = storage[ (storage.length * 0.75).to_i ]
  theoretical_bottom = storage[ (storage.length * 0.25).to_i ]

  puts "Theoretical top    is: #{theoretical_top}"
  puts "Theoretical median is: #{theoretical_median}"
  puts "Theoretical bottom is: #{theoretical_bottom}"
end
