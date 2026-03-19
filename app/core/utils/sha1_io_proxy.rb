require 'digest/sha1'

module PatchKitTools
  class SHA1IOProxy
    def initialize(io)
      @io = io
      @sha1 = Digest::SHA1.new
      @closed = false
    end

    def write(string)
      raise IOError, "closed stream" if @closed
      @sha1.update(string)
      @io.write(string)
    end

    alias << write

    def print(*objs)
      objs.each { |obj| write(obj.to_s) }
      nil
    end

    def puts(*objs)
      objs.each do |obj|
        write(obj.to_s)
        write("\n") unless obj.to_s.end_with?("\n")
      end
      write("\n") if objs.empty?
      nil
    end

    def close
      return if @closed
      @io.close
      @closed = true
    end

    def closed?
      @closed
    end

    def sha1
      raise IOError, "Cannot calculate SHA1 for open stream" unless @closed
      @sha1.hexdigest
    end
  end
end