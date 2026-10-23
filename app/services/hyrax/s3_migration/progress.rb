# frozen_string_literal: true

module Hyrax
  module S3Migration
    # Prints a progress line every PROGRESS_EVERY items (default 500; 0 turns it off), so long runs show
    # signs of life, how fast they are going, and what they have found so far.
    class Progress
      # @param detail [#call, nil] returns extra text for each line, e.g. running counts
      def initialize(every: ENV.fetch('PROGRESS_EVERY', 500).to_i, out: $stdout, detail: nil, clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) })
        @every = every
        @out = out
        @detail = detail
        @clock = clock
        @started = clock.call
        @count = 0
      end

      def tick
        @count += 1
        report if @every.positive? && (@count % @every).zero?
      end

      private

      def report
        elapsed = @clock.call - @started
        line = format('  ... %d examined (%.1f/s, %s elapsed)', @count, @count / [elapsed, 0.001].max, duration(elapsed))
        line += "  #{@detail.call}" if @detail
        @out.puts(line)
        @out.flush
      end

      def duration(seconds)
        minutes, secs = seconds.to_i.divmod(60)
        hours, minutes = minutes.divmod(60)
        hours.positive? ? format('%d:%02d:%02d', hours, minutes, secs) : format('%d:%02d', minutes, secs)
      end
    end
  end
end
