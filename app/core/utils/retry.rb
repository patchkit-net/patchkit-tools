class Retry
  def self.on(*retry_errors, max_attempts: 10, pause_seconds: 10, error_message: 'Got error: {}')
    attempt = 1

    begin
      yield
    rescue => raised
      if retry_errors.find { |e| raised.is_a? e }
        puts error_message.gsub('{}', raised.message)

        if attempt >= max_attempts
          puts "Reached max attempts #{max_attempts}"
          raise raised
        end

        attempt += 1

        puts "Retrying in #{pause_seconds} (attempt #{attempt}/#{max_attempts})..."
        sleep pause_seconds

        retry
      else
        raise
      end
    end
  end
end