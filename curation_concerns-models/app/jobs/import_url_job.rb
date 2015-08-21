require 'net/https'
require 'uri'
require 'tempfile'

class ImportUrlJob < ActiveFedoraIdBasedJob
  def queue_name
    :import_url
  end

  def run
    user = User.find_by_user_key(generic_file.depositor)

    Tempfile.open(id.tr('/', '_')) do |f|
      copy_remote_file(generic_file.import_url, f)
      # attach downloaded file to generic file stubbed out
      if CurationConcerns::GenericFileActor.new(generic_file, user).create_content(f)

        # send message to user on download success
        if CurationConcerns.config.respond_to?(:after_import_url_success)
          CurationConcerns.config.after_import_url_success.call(generic_file, user)
        end
      else

        # send message to user on download failure
        if CurationConcerns.config.respond_to?(:after_import_url_failure)
          CurationConcerns.config.after_import_url_failure.call(generic_file, user)
        end
      end
    end
  end

  def copy_remote_file(_import_url, f)
    f.binmode
    # download file from url
    uri = URI(generic_file.import_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https' # enable SSL/TLS
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    mime_type = nil

    http.start do
      http.request_get(uri.request_uri) do |resp|
        mime_type = resp.content_type
        resp.read_body do |segment|
          f.write(segment)
        end
      end
    end
    f.rewind
  end

  def job_user
    User.batchuser
  end
end
