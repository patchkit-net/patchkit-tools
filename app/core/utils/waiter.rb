class Waiter
    def self.wait_for(timeout:, interval: 5, &block)
        raise "block required" unless block_given?
            
        start_time = Time.now

        loop do
            result = block.call

            return result if result

            if Time.now - start_time > timeout
                raise "timeout"
            end

            sleep interval
        end
    end
end