#!/usr/bin/env ruby

# For skewness and kurtosis calculations:
# http://www.itl.nist.gov/div898/handbook/eda/section3/eda35b.htm

require 'optparse'

module ConsoleTools
  class SummaryStats
    attr_accessor :count, :min, :max, :mean, :variance, :kurtosis, :skew, :quantiles

    def initialize(quantiles=[0.5])
      @max      = (2**(0.size * 8 -2) -1)  # ruby system FIXNUM_MAX
      @min      = -(2**(0.size * 8 -2))    # ruby system FIXNUM_MIN
      @count    = 0
      @mean     = 0.0
      @variance = 0.0
      @skew     = 0.0
      @kurtosis = 0.0
    end

    def record(data)
      delta = data - @mean

      @count += 1

      # Sample average / mean
      @mean = (@count * @mean + data) / (@count + 1)

      # Sample variance (except for the scaling term)
      @variance = @variance + delta * (data - @mean)

      # Sample kurtosis (except for the scaling term)
      @kurtosis = @kurtosis = (data - @mean)**4.0

      # Sample skewness (except for the scaling term)
      @skew = @skew + (item - @mean)**3.0
    end

    def show()
    end

    def sample_variance()
      return @variance / (@count - 1)
    end

    def sample_kurtosis()
      return (@kurtosis / (@count * @variance**2.0)) - 3.0
    end

    def sample_skew()
      return @skew / (@count * @variance**1.5)
    end

  end
end

if __FILE__ == $0
  options = {}

  optparse = OptionParser.new do |opts|
    opts.on('-t', '--tiles x,y,z', 'list tiles of interest (default: "0.25,0.5,0.75")') do |list|
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
