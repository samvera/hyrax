module Hyrax
  class FileSetFixityCheckService
    attr_reader :file_set, :id

    # @param file_set [ActiveFedora::Base, String] file_set
    def initialize(file_set)
      if file_set.is_a?(String)
        @id = file_set
      else
        @id = file_set.id
        @file_set = file_set
      end
    end

    NO_RUNS = 999

    # provides a human readable version of the fixity check status
    # This may trigger fixity checks if required
    # @param [Hydra::PCDM::File] file the file to get the fixity check status for,
    #                                 defaults to the original_file.
    def human_readable_fixity_check_status(file = file_set.original_file)
      fixity_check_stat(file)
    end

    # Check the file by only what is in the fixity check log.
    # Do not try to access the versions if we do not have access to them.
    # Use this when a file_set is loaded from solr instead of fedora
    def logged_fixity_status
      fixity_results = ChecksumAuditLog.logs_for(id, "original_file")
                                       .collect { |result| result["pass"] }

      if !fixity_results.empty?
        stat_to_string(fixity_results.reduce(true) { |sum, value| sum && value })
      else
        'Fixity checks have not yet been run on this file.'
      end
    end

    # Fixity checks each version of each file if it hasn't been checked recently
    # Returns the set of most recent fixity check status for each version of the
    # content file
    # @param [Hash] log container for messages, mapping file ids to status
    def fixity_check(log = {})
      file_set.files.each { |f| log[f.id] = fixity_check_file(f) }
      log
    end

    private

      def stat_to_string(stat)
        case stat
        when 0
          'failing'
        when 1
          'passing'
        else
          raise ArgumentError, "Unknown status `#{stat}'"
        end
      end

      # Retrieve or generate the fixity check for a file (all versions are checked for versioned files)
      # @param [ActiveFedora::File] file to fixity check
      # @param [Array] log container for messages
      def fixity_check_file(file, log = [])
        versions = file.has_versions? ? file.versions.all : file
        versions.each { |v| log << fixity_check_file_version(file.id, v.uri) }
        log
      end

      # Retrieve or generate the fixity check for a file and provide a human-readable status message.
      # @param [ActiveFedora::File] file to fixity check
      def fixity_check_stat(file)
        fixity_results = fixity_check_file(file).collect { |result| result['pass'] }
        # check how many non runs we had
        non_runs = fixity_results.reduce(0) { |sum, value| value == NO_RUNS ? sum + 1 : sum }
        build_fixity_check_stat_message(fixity_results, non_runs)
      end

      def build_fixity_check_stat_message(fixity_results, non_runs)
        if non_runs.zero?
          result = fixity_results.reduce(true) { |sum, value| sum && value }
          stat_to_string(result)
        elsif non_runs < fixity_results.length
          result = fixity_results.reduce(true) { |sum, value| value == NO_RUNS ? sum : sum && value }
          "Some fixity checks have not been run, but the ones run were #{stat_to_string(result)}."
        else
          'Fixity checks have not yet been run on this file.'
        end
      end
      private :build_fixity_check_stat_message

      # Retrieve or generate the fixity check for a specific version of a file
      # @param [String] file_id used to find the file within its parent object (usually "original_file")
      # @param [String] version_uri the version to be fixity checked (or the file uri for non-versioned files)
      def fixity_check_file_version(file_id, version_uri)
        latest_fixity_check = ChecksumAuditLog.logs_for(file_set.id, file_id).first
        return latest_fixity_check unless needs_fixity_check?(latest_fixity_check)
        FixityCheckJob.perform_later(file_set, file_id, version_uri.to_s)
        latest_fixity_check || ChecksumAuditLog.new(pass: NO_RUNS, file_set_id: file_set.id, file_id: file_id, version: version_uri)
      end

      # Check if time since the last fixity check is greater than the maximum days allowed between fixity checks
      # @param [ChecksumAuditLog] latest_fixity_check the most recent fixity check
      def needs_fixity_check?(latest_fixity_check)
        return true unless latest_fixity_check
        unless latest_fixity_check.updated_at
          logger.warn "***FIXITY*** problem with fixity check log! Latest Fixity check is not nil, but updated_at is not set #{latest_fixity_check}"
          return true
        end
        days_since_last_fixity_check(latest_fixity_check) >= Hyrax.config.max_days_between_fixity_checks
      end

      # Return the number of days since the latest fixity check
      # @param [ChecksumAuditLog] latest_fixity_check the most recent fixity check
      def days_since_last_fixity_check(latest_fixity_check)
        (DateTime.current - latest_fixity_check.updated_at.to_date).to_i
      end

      # Loads the FileSet from Fedora if needed
      def file_set
        @file_set ||= FileSet.find(id)
      end
  end
end
