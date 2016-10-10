require 'open3'

class ImportExportJob < ActiveJob::Base
  attr_reader :mode
  include Open3

  # @param [String] uri of the resource
  # @option opts [String] desc_dir location of descriptions
  # @option opts [String] bin_dir location of binaries
  # @option opts [String] profile BagIt profile
  # @option opts [String] mode import or export mode
  # Notes:
  #   * the Fedora import-export tool is not release yet
  #   * current parameters are undergoing changes
  #   * import features are not yet available
  #   * exporting bags is not yet supported
  def perform(uri, options = {})
    @mode = options.fetch(:mode, "export")
    call(uri,
         options.fetch(:desc_dir, CurationConcerns.config.descriptions_directory),
         options.fetch(:bin_dir, CurationConcerns.config.binaries_directory),
         options.fetch(:profile, nil))
  end

  private

    def call(uri, desc_dir, bin_dir, _profile = nil)
      command = "java -jar #{CurationConcerns.config.import_export_jar_file_path} --mode #{mode} --resource #{uri} --descDir #{desc_dir} --binDir #{bin_dir}"
      internal_call(command)
    end

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
