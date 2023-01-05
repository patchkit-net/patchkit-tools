class Stopwatch
  class << self
    def measure(label: nil, output: STDOUT)
      start = Time.now

      yield

      elapsed = Time.now - start
      if label
        output.puts "#{label} took #{"%.2f" % elapsed} seconds"
      end

      elapsed
    end
  end
end