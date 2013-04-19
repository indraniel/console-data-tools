#!/usr/bin/env ruby
#
# curl -s -L "http://ichart.finance.yahoo.com/table.csv?s=GOOG&d=3&e=19&f=2013&g=d&a=7&b=19&c=2004&ignore=.csv" |cut -d, -f5 |tail -n +2 | ~/Dropbox/code/hist.rb -s 10.0
#
# awk 'func r(){return sqrt(-2*log(rand()))*cos(6.2831853*rand())}BEGIN{for(i=0;i<10000;i++)s=s"\n"0.5*r();print s}' | ~/Dropbox/code/hist.rb -s 0.1 -c

require 'optparse'

class Histogram
  attr_accessor :step, :complete, :columns, :total

  def initialize(stepsize=1.0, columns=80, complete=false)
    @freq     = Hash.new(0)
    @total    = 0
    @step     = stepsize
    @columns  = columns
    @complete = complete
  end

  def record(data)
    bin = (data/@step).to_i
    @freq[bin] += 1
    @total += 1
  end

  def calc_stars(freq, max_freq)

    num_stars = freq.to_f

    if max_freq >= @columns
      num_stars = ((freq.to_f / max_freq) * @columns)
    end

    num_stars
  end

  def show()

    min = @freq.values.min;
    max = @freq.values.max;

    bins = @freq.keys.sort

    bins.each do |i|
      stars = self.calc_stars(@freq[i], max)
      puts "%6s | %6d | %s" % [ sprintf("%3.3f", i * step), @freq[i], '*' * stars ]
    end
    puts "TOTAL  | %6d |" % total
  end
end



if __FILE__ == $0
  options = {}

  optparse = OptionParser.new do |opts|
    options[:step] = 1.0
    opts.on('-s', '--step STEPSIZE', 'set the bin width (default=1.0)') do |step|
      options[:step] = step.to_f
    end

    options[:columns] = 80
    opts.on('-c', '--columns COLUMNS', 'max width of histogram (default=80)') do |cols|
      options[:columns] = cols.to_i
    end

    opts.on('-h', '--help', 'show the help menu') do
      puts opts
      exit(0)
    end
  end

  optparse.parse!

  h = Histogram.new(options[:step], options[:columns])

  ARGF.each_line do |e|
    data = e.strip.to_f
    h.record(data)
  end

  h.show
end
