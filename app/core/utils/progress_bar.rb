require 'io/console'
require 'thread'

class ProgressBar
  attr_writer :limit_per_second

  def initialize(total)
    @total = total
    @lines_taken = 0
    @semaphore = Mutex.new
    @last_print_time = 0
    @limit_per_second = 2
  end

  def print(progress, status, force: false)
    return unless force || can_print?
    status ||= ""

    return unless @semaphore.try_lock

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

    @last_print_time = Time.now.to_f
  ensure
    @semaphore.unlock if @semaphore.owned?
  end

  private

    def can_print?
      (Time.now.to_f - @last_print_time) >= 1.0 / @limit_per_second
    end

    def get_progress_value(progress)
      [[progress.to_f / @total.to_f, 0].max, 1].min
    end
end
