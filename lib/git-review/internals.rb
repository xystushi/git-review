module Internals

  private

  # System call to 'git'.
  def git_call(command, verbose = debug_mode, enforce_success = false)
    if verbose
      puts
      puts "  git #{command}"
      puts
    end
    output = `git #{command}`
    puts output if verbose and not output.empty?
    # If we need sth. to succeed, but it doesn't, then stop right there.
    if enforce_success and not last_command_successful?
      puts output unless output.empty?
      raise ::GitReview::Errors::UnprocessableState
    end
    output
  end

  # @return [Boolean] whether the last issued system call was successful
  def last_command_successful?
    $?.exitstatus == 0
  end

  def debug_mode
    ::GitReview::Settings.instance.review_mode == 'debug'
  end

  # display helper to make output more configurable
  def format_text(info, size)
    info.to_s.gsub("\n", ' ')[0, size-1].ljust(size)
  end


  # display helper to unify time output
  def format_time(time_string)
    Time.parse(time_string).strftime('%d-%b-%y')
  end

end