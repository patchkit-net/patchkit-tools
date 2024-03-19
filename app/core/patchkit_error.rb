module PatchKitTools
  class CommandLineError < StandardError
  end
  class APIError < StandardError
    attr_reader :url
    attr_reader :body
    attr_reader :code
    attr_reader :msg
    
    def initialize(url, code, msg, body)
      @url = url
      @code = code
      @msg = msg
      @body = body

      super("[#{code}] #{msg} while requesting #{url}: #{body}")
    end
  end
  class APIJobError < APIError
  end
  class APIPublishError < StandardError
  end

  class CannotReadStdinError < StandardError
    def initialize(message = 'Cannot read from stdin')
      super(message)
    end
  end
end
