require 'net/https'
require 'uri'
require 'tempfile'

class ImportUrlJob < ActiveFedoraIdBasedJob
  queue_as :import_url

  def perform(id)
    @id = id
    user = User.find_by_user_key(file_set.depositor)

    Tempfile.open(id.tr('/', '_')) do |f|
      copy_remote_file(file_set.import_url, f)
      # attach downloaded file to generic file stubbed out
      if CurationConcerns::FileSetActor.new(file_set, user).create_content(f)

        # send message to user on download success
        if CurationConcerns.config.respond_to?(:after_import_url_success)
          CurationConcerns.config.after_import_url_success.call(file_set, user)
        end
      else

        # send message to user on download failure
        if CurationConcerns.config.respond_to?(:after_import_url_failure)
          CurationConcerns.config.after_import_url_failure.call(file_set, user)
        end
      end
    end
  end

  def copy_remote_file(_import_url, f)
    f.binmode
    # download file from url
    uri = URI(file_set.import_url)
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
end
