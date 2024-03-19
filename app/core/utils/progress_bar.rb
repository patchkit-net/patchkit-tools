require 'io/console'
require 'thread'
require_relative '../patchkit_config'

class ProgressBar
  attr_writer :limit_per_second

  def initialize(total)
    @total = total.to_f
    @last_print_time = Time.now
    @last_line_length = 0 # Initialize the last line length
    @limit_per_second = 1 # Default to updating once per second
  end

  def print(progress, status, force: false)
    current_time = Time.now
    # Calculate if we should update the progress bar based on the limit_per_second
    should_print = force || (current_time - @last_print_time) > (1.0 / @limit_per_second)
    return unless should_print
    return unless PatchKitConfig.show_progress_bar_updates

    # Update the progress display
    percent = (progress.to_f / @total * 100).round(2)
    progress_bar = "=" * (percent / 10).to_i + " " * (10 - percent / 10).to_i
    line = "[#{progress_bar}] #{percent}% - #{status}"

    # Clear the last printed line by overwriting it with spaces if necessary
    clear_line = " " * [@last_line_length, line.length].max

    $stdout.print "\r#{clear_line}\r" # Overwrite the old line with spaces, then return to the start of the line
    $stdout.print line # Print the new progress bar and status
    $stdout.flush

    @last_print_time = current_time
    @last_line_length = line.length # Remember the new line length for next update
  end
end
