#!/usr/bin/env ruby
#
# curl -s -L "http://ichart.finance.yahoo.com/table.csv?s=GOOG&d=3&e=19&f=2013&g=d&a=7&b=19&c=2004&ignore=.csv" |cut -d, -f5 |tail -n +2 | ~/Dropbox/code/hist.rb -s 10.0
#
# awk 'func r(){return sqrt(-2*log(rand()))*cos(6.2831853*rand())}BEGIN{for(i=0;i<10000;i++)s=s"\n"0.5*r();print s}' | ~/Dropbox/code/hist.rb -s 0.1 -c

require 'optparse'

def get_range(min_range, max_range, step)
  range = []

  r = min_range
  while (r <= max_range) do
    range << r
    r += step
  end

  range
end

def calc_stars(freq, max_freq)
  cols = ENV['COLUMNS'] || 80

  num_stars = freq.to_f

  if max_freq >= cols
    num_stars = ((freq.to_f / max_freq) * cols)
  end

  num_stars
end

def histogram(freq={}, total=0, step=1, complete=false)

  min = freq.values.min;
  max = freq.values.max;

  bins = freq.keys.map &:to_s
  bins.map! &:to_f

  if complete
    min_range, max_range = [bins.min, bins.max]
    bins = get_range(min_range, max_range, step)
  else
    bins.sort!
  end

  bins.each do |i|
    k = i.to_i.to_s.to_sym
    stars = calc_stars(freq[k], max)
    puts "%6s | %6d | %s" % [ sprintf("%3.3f", i * step), freq[k], '*' * stars ]
  end
  puts "TOTAL  | %6d |" % total
end

if __FILE__ == $0
  options = {}

  optparse = OptionParser.new do |opts|
    options[:step] = 1.0
    opts.on('-s', '--step STEPSIZE', 'set the bin size (default=1.0)') do |step|
      options[:step] = step
    end

    options[:complete] = false
    opts.on('-c', '--complete', 'Show the full histogram range') do
      options[:complete] = true
    end

    opts.on('-h', '--help', 'show the help menu') do
      puts opts
      exit(0)
    end
  end

  optparse.parse!

  stepsize = options[:step].to_f
  freq  = Hash.new(0)
  total = 0

  ARGF.each_line do |e|
    data = e.strip.to_f
    bin  = (data/stepsize).to_i.to_s.to_sym
    freq[bin] += 1
    total += 1
  end

  histogram(freq, total, stepsize, options[:complete])
  puts "\n"
end
