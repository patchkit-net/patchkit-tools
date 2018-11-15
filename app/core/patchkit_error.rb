module PatchKitTools
  class CommandLineError < StandardError
  end
  class APIError < StandardError
  end
  class APIJobError < APIError
  end
  class APIPublishError < StandardError
  end
end
