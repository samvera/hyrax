# frozen_string_literal: true

module Hyrax
  ##
  # The default virus scanner ported from +Hyrax::Works+.
  #
  # If ClamAV is present, it will be used to check for the presence of a virus.
  # If ClamAV is not installed or otherwise not available to your application,
  # +Hyrax::Works+ does no virus checking add assumes files have no viruses.
  #
  # @example to use a virus checker other than Hyrax::VirusScanner:
  #   class MyScanner < Hyrax::Works::VirusScanner
  #     def infected?
  #       my_result = Scanner.check_for_viruses(file)
  #       [return true or false]
  #     end
  #   end
  #
  #   # Then set Hyrax::Works to use your scanner either in a config file or initializer:
  #   Hyrax.config.virus_scanner = MyScanner
  #
  class VirusScanner
    attr_reader :file

    ##
    # @api public
    # @param file [String]
    def self.infected?(file)
      new(file).infected?
    end

    def initialize(file)
      @file = file
    end

    ##
    # @note Override this method to use your own virus checking software
    #
    # @return [Boolean]
    def infected?
      defined?(ClamAV) ? clam_av_scanner : null_scanner
    end

    def clam_av_scanner
      scan_result = ClamAV.instance.method(:scanfile).call(file)
      return false if scan_result.zero?
      warning "A virus was found in #{file}: #{scan_result}"
      true
    end

    ##
    # Always return zero if there's nothing available to check for viruses.
    # This means that we assume all files have no viruses because we can't
    # conclusively say if they have or not.
    def null_scanner
      warning "Unable to check #{file} for viruses because no virus scanner is defined" unless
        Rails.env.test?
      false
    end

    private

    def warning(msg)
      Hyrax.logger&.warn(msg)
    end
  end
end
