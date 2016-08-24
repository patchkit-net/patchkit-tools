require 'io/console'

# Console progress bar
class ProgressBar
  def initialize(total)
    @total = total
    @lines_taken = 0
  end

  # Displays progress bar
  def print(progress, status)
    console_width = IO.console.winsize[1]
    if @lines_taken > 0
      $stdout.syswrite "\e[1A\r"
      $stdout.syswrite " " * @previous_status_length if @previous_status_length > status.length
      $stdout.syswrite "\e[#{@lines_taken - 1}A\r"
    end

    progress_bar_length = console_width - 5
    progress_length = (progress_bar_length.to_f * get_progress_value(progress)).round
    if(progress_length == progress_bar_length)
      $stdout.syswrite "|#{'=' * progress_length}|\n#{status}\n"
    else
      remaining_length = progress_bar_length - progress_length
      $stdout.syswrite "|#{'=' * [0, (progress_length - 1)].max}#{'>' * [1, (progress_length)].min}#{'-' * remaining_length}|\n#{status}\n"
    end
    $stdout.flush
    @lines_taken = (status.length.to_f / console_width.to_f).ceil + 1
    @previous_status_length = status.length
  end

  private

  def get_progress_value(progress)
    return [[progress.to_f / @total.to_f, 0].max, 1].min
  end
end
