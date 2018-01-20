require 'io/console'
require 'thread'

class ProgressBar
  def initialize(total)
    @total = total
    @lines_taken = 0
    @semaphore = Mutex.new
  end

  def print(progress, status)
    begin
      if status.nil?
        status = ""
      end

      if @semaphore.try_lock
        console_width = IO.console.winsize[1]

        return if console_width < 6

        if @lines_taken > 0
          $stdout.write "\e[1A\r"
          $stdout.write " " * @previous_status_length if @previous_status_length > status.length
          $stdout.write "\e[#{@lines_taken - 1}A\r"
          $stdout.flush
        end

        progress_bar_length = console_width - 5
        progress_length = (progress_bar_length.to_f * get_progress_value(progress)).round
        if progress_length == progress_bar_length
          $stdout.write "|#{'=' * progress_length}|\n#{status}\n"
        else
          remaining_length = progress_bar_length - progress_length
          $stdout.write "|#{'=' * [0, (progress_length - 1)].max}#{'>' * [1, (progress_length)].min}#{'-' * remaining_length}|\n#{status}\n"
        end
        $stdout.flush
        @lines_taken = (status.length.to_f / console_width.to_f).ceil + 1
        @previous_status_length = status.length
      end
    ensure
      @semaphore.unlock
    end
  end

  private

  def get_progress_value(progress)
    [[progress.to_f / @total.to_f, 0].max, 1].min
  end
end
