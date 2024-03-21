require_relative 'model/global_lock'

module PatchKitTools
  module Lockable

    # Acquires global lock for given resource. If block is provided, it will be called as a safety check before
    # the lock is acquired and after the lock is acquired.
    # If the block returns false before the lock is acquired, it will retry until it returns true or timeout is reached.
    def acquire_global_lock!(resource, timeout: 3600 * 6)
      raise "Already holding a global lock" if @global_lock
      raise "Block required" unless block_given?

      resource_name =
        if resource.is_a? String
          resource
        else
          resource.path
        end

      # there's a secondary check in the block that should be performed and return true
      if block_given?
        start_time = Time.now

        loop do
          result = yield
          break if result

          if Time.now - start_time > timeout
            raise "Timeout waiting for lock on #{resource_name}"
          end

          puts "Trying again in 60 seconds..."
          sleep 60
        end
      end

      @global_lock = GlobalLock.wait_for(resource: resource_name)

      if block_given?
        unless yield
          raise <<~ERROR
            Global lock safety check failed.
            Normally this shouldn't happen. Make sure that the latest version of patchkit-tools is installed
            on all machines that are using it.
          ERROR
        end
      end
    end

    def release_global_lock!
      @global_lock&.release
      @global_lock = nil
    end

    def acquire_app_processing_global_lock!(app, timeout: 3600 * 6)
      start_time = Time.now
      acquire_global_lock!(app, timeout: timeout) do
        # safety check
        while app.reload.processing_version?
          if Time.now - start_time > timeout
            return false
          end

          puts "Application version is currently being processed. Checking again in 60 seconds..."
          sleep 60
        end

        while app.reload.publishing_version?
          if Time.now - start_time > timeout
            return false
          end

          puts "Application version is currently being published. Checking again in 60 seconds..."
          sleep 60
        end

        true
      end
    end
  end
end