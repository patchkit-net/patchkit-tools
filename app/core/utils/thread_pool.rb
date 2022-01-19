class ThreadPool
  def initialize(size:)
    @size = [[size, 1].max, 32].min
    @semaphore = Mutex.new
    @jobs = Queue.new
  end

  def enqueue(&job)
    @jobs << job
  end

  def execute
    workers = (0..(@size - 1)).map do
      Thread.new do
        begin
          while true
            job = nil
            @semaphore.synchronize do
              job = @jobs.pop(true)
            end

            break unless job
            job.call
          end
        rescue ThreadError
        end
      end
    end

    workers.map(&:join)
  end
end