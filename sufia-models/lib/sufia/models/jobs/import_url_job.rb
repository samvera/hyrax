require 'net/https'
require 'uri'
require 'tempfile'

class ImportUrlJob < ActiveFedoraPidBasedJob

  def queue_name
    :import_url
  end

  def run
    user = User.find_by_user_key(generic_file.depositor)

    Tempfile.open(self.pid) do |f|
      f.binmode

      # download file from url
      uri = URI(generic_file.import_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"  # enable SSL/TLS
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      http.start do
        http.request_get(uri.request_uri) do |resp|
          resp.read_body do |segment|
            f.write(segment)
          end
        end
      end

      f.rewind
      # attach downloaded file to generic file stubbed out
      Sufia::GenericFile::Actions.create_content(generic_file, f, File.basename(uri.path), 'content', user)
      Sufia.queue.push(ContentDepositEventJob.new(generic_file.pid, generic_file.depositor))
      # add message to user for downloaded file
      message = "The file (#{File.basename(uri.path)}) was successfully imported."
      job_user.send_message(user, message, 'File Import')
    end
  rescue => error
    job_user.send_message(user, error.message, 'File Import Error')
  end

  def job_user
    User.batchuser
  end
end
