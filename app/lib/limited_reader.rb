module PatchKitTools

  # reads up to number of bites from given io
  class LimitedReader
    def initialize(input_io, limit)
      @input_io = input_io
      @remaining = limit
    end

    def read(size = 0, outbuf = nil)
      return nil if eof?
      size = @remaining if size == 0

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
