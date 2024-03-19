require 'securerandom'

require_relative 'abstract_model'
require_relative '../utils/retry'
require_relative '../patchkit_config'

module PatchKitTools
  module Model
    class GlobalLock < AbstractModel
      attr_reader :thread

      OWNER = SecureRandom.uuid

      LOCK_POLL_INTERVAL_SECONDS = 30
      LOCK_TIMEOUT_SECONDS = 3600 * 6 # six hours
      def initialize(data)
        @data = data
        super "1/global_locks"

        if !owner || !resource
          puts "Can't initialize GlobalLock without owner and resource"
          return
        end

        if status == 'allow'
          @thread = Thread.new do
            begin
              puts "Starting global lock thread for #{resource}..." if PatchKitConfig.debug

              loop do
                sleep LOCK_POLL_INTERVAL_SECONDS

                # try refresh the lock
                GlobalLock.acquire_inner(resource, error_message: "Error refreshing global lock: {}")
              end
            rescue Exception => e
              puts "Error in global lock thread: #{e}"
              puts e.backtrace.join("\n")
            end
          end
        end
      end

      def self.acquire(resource:)
        if block_given?
          begin
            lock = self.wait_for(resource: resource)
            yield lock
          ensure
            lock.release
          end
        else
          data = acquire_inner(resource, error_message: "Error acquiring global lock: {}")
          GlobalLock.new(data)
        end
      end

      def self.wait_for(resource:, timeout: PatchKitConfig.global_lock_timeout)
        lock = nil
        start_time = Time.now
        loop do
          lock = self.acquire(resource: resource)
          break if lock.status == 'allow'

          if Time.now - start_time > timeout
            raise "Timeout waiting for lock on #{resource}"
          end

          puts "Waiting for lock on #{resource} (peers in front of me: #{lock.queue_position})"

          sleep LOCK_POLL_INTERVAL_SECONDS
        end

        lock
      end

      def release
        puts "Releasing global lock on #{resource}..." if PatchKitConfig.debug
        @thread&.kill
        @thread = nil
      end

      def self.acquire_inner(resource, error_message:)
        puts "Acquiring global lock on #{resource}, owner: #{OWNER}..." if PatchKitConfig.debug

        Retry.on(StandardError, max_attempts: 5, pause_seconds: 5, error_message: error_message) do
          result = PatchKitAPI.post(construct_path("1/global_locks/acquire"), params: { resource: resource, owner: OWNER })
          puts "Global lock acquired on #{resource}: #{result}" if PatchKitConfig.debug
          result
        end
      end
    end
  end
end