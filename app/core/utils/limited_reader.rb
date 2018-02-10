module PatchKitTools

  # reads up to number of bites from given io
  class LimitedReader
    attr_reader :remaining

    def initialize(input_io, limit)
      @input_io = input_io
      @remaining = limit

      @on_read = []
    end

    def on_read(&callback)
      @on_read << callback
    end

    def read(size = 0, outbuf = nil)
      return nil if eof?
      size = @remaining if size == 0

      @on_read.each(&:call)

      if outbuf.is_a? String
        outbuf.clear
      else
        outbuf = ''
      end

      size = [size, @remaining].min

      outbuf << @input_io.read(size)
      @remaining -= outbuf.bytesize

      outbuf
    end

    def eof?
      @remaining.zero? || @input_io.eof?
    end
  end
end
