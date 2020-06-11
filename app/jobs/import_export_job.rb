# frozen_string_literal: true
require 'open3'

class ImportExportJob < ApplicationJob
  include Open3

  # @param resource [String] uri of the resource
  # @param mode [String] "import" or "export" mode
  # @param dir [String] location of export
  # TODO: Support BagIt profile
  def perform(resource:, mode: 'export', dir: Hyrax.config.bagit_dir)
    command = "java -jar #{Hyrax.config.import_export_jar_file_path} --mode #{mode} --resource #{resource} --dir #{dir}"
    internal_call(command)
  end

  private

  def internal_call(command)
    stdin, stdout, stderr, wait_thr = popen3(command)
    begin
      out = stdout.read
      err = stderr.read
      exit_status = wait_thr.value
      raise "Fedora command failed: \"#{command}\"\n#{err}" unless exit_status.success?
      out
    ensure
      stdin.close
      stdout.close
      stderr.close
    end
  end
end
