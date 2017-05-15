module Hyrax
  # Creates fixity status messages to display to user, for a fileset, or
  # a specific version/file within it. Determines status by looking up
  # existing ChecksumAuditLog objects, does not actually do a check itself.
  # See FileSetFixityCheckService and ChecksumAuditLog for actually performing
  # checks and recording as ChecksumAuditLog objects.
  class FixityStatusService
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::TextHelper
    include ActionView::Helpers::OutputSafetyHelper

    attr_reader :file_set_id, :relevant_log_records
    def initialize(file_set_id)
      @file_set_id = file_set_id
    end

    # Returns a html_safe string communicating fixity status checks,
    # possibly on multiple files/versions.
    def file_set_status
      @file_set_status ||=
        if relevant_log_records.empty?
          "Fixity checks have not yet been run on this object"
        elsif failing_checks.empty?
          content_tag("span", "passed", class: "label label-success") + ' ' + render_existing_check_summary
        else
          content_tag("span", "FAIL", class: "label label-danger") + ' ' + render_existing_check_summary + render_failed_table
          # TODO details on failures.
        end
    end

    protected

    def render_failed_table
      safe_join([
        "<table>".html_safe,
        "<tr><th>File</td><th>Checked URI</th><th>Expected</th><th>Date</th></tr>".html_safe,
        *failing_checks.collect do |log|
          safe_join([
            "<tr>".html_safe,
              content_tag("td", content_tag("a",
                                            log.file_id,
                                            href: "#{Hydra::PCDM::File.translate_id_to_uri.call(log.file_id)}/fcr:metadata")),
              content_tag("td", content_tag("a", log.checked_uri, href: log.checked_uri)),
              content_tag("td", log.expected_result),
              content_tag("td", log.created_at.to_s),
            "</tr>".html_safe
          ])
        end,
        "</table>".html_safe
      ])
    end

    def render_existing_check_summary
      @render_existing_check_summary ||=
        "#{pluralize num_checked_files, 'File'} with #{pluralize relevant_log_records.count, "total version"} checked #{render_date_range}"
    end

    def render_date_range
      @render_date_range ||= begin
        from = relevant_log_records.min_by(&:created_at).created_at.to_s
        to   = relevant_log_records.max_by(&:created_at).created_at.to_s
        if from == to
          from
        else
          "between #{from} and #{to}"
        end
      end
    end

    # Should be all _latest_ ChecksumAuditLog about different files/versions
    # currently existing in specified FileSet.
    def relevant_log_records
      @relevant_log_records = ChecksumAuditLog.latest_for_file_set_id(file_set_id)
    end

    def num_checked_files
      @num_relevant_files ||= relevant_log_records.group_by(&:file_id).keys.count
    end

    def failing_checks
      @failing_checks ||= relevant_log_records.find_all(&:failed?)
    end

  end
end
