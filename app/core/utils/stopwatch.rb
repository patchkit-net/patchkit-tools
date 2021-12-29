class Stopwatch
  class << self
    def measure(label: nil)
      start = Time.now

      yield

      elapsed = Time.now - start
      if label
        puts "#{label} took #{"%.2f" % elapsed} seconds"
      end

      elapsed
    end
  end
end