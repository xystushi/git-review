module GitReview

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
        raise ::GitReview::UnprocessableState
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
    def format_time(time)
      t = time.is_a?(Time) ? time : Time.parse(time)
      t.strftime('%d-%b-%y')
    end

  end

end

# patch Sawyer::Resource so that it is serializable after converting to Mash
module Sawyer

  class Resource

    def to_mash
      hash = Hashie::Mash.new(self.to_hash)
      hash.each do |k,v|
        hash[k] = v.to_mash if v.respond_to?(:to_mash)
      end
    end

  end

end

class Array

  def to_mash
    self.collect { |e| e.respond_to?(:to_mash) ? e.to_mash : e }
  end

end
