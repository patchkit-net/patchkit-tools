require 'thread'

class ThreadPoolWorker
  def initialize(size:)
    @size = [[size, 1].max, 32].min
    @queue = []
    @semaphore = Mutex.new
  end

  def schedule(&block)
    raise "expected a block" unless block_given?
    @semaphore.synchronize do
      @queue << block
    end

    proceed
  end

  private

    def proceed
      @semaphore.synchronize do
        return if @queue.empty?

        first = @queue.first
        @queue = @queue[1..-1]
      end

      
    end
end