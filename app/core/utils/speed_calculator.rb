module PatchKitTools
  class SpeedCalculator
    attr_accessor :buffer_seconds

    Entry = Struct.new(:time, :number)

    def initialize
      @buffer_seconds = 3
      @entries = []
    end

    def submit(number)
      @entries << Entry.new(Time.now.to_f, number)
      remove_old_entries!
    end

    def ready?
      @ready
    end

    def speed_per_second
      return 0 if @entries.first == @entries.last
      time_delta = @entries.last.time - @entries.first.time
      (@entries.last.number - @entries.first.number) / time_delta
    end

    private

      def remove_old_entries!
        now = Time.now.to_f
        count = @entries.size
        @entries.reject! { |e| e.time + @buffer_seconds < now }
        @ready = count != @entries.size unless ready?
      end
  end
end
