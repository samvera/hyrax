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
      path = copy_remote_file(generic_file.import_url, f)
      # attach downloaded file to generic file stubbed out
      if Sufia::GenericFile::Actor.new(generic_file, user).create_content(f, path, 'content')
        # add message to user for downloaded file
        message = "The file (#{generic_file.content.label}) was successfully imported."
        job_user.send_message(user, message, 'File Import')
      else
        job_user.send_message(user, generic_file.errors.full_messages.join(', '), 'File Import Error')
      end
    end
  end

  def copy_remote_file(import_url, f)
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
    uri.path
  end

  def job_user
    User.batchuser
  end
end
