require 'net/https'
require 'uri'
require 'tempfile'

class ImportUrlJob < ActiveJob::Base
  queue_as :import_url

  before_enqueue do |job|
    log = job.arguments.last
    log.pending_job(job)
  end

  def perform(file_set, log)
    log.performing!
    user = User.find_by_user_key(file_set.depositor)

    Tempfile.open(file_set.id.tr('/', '_')) do |f|
      copy_remote_file(file_set, f)

      # reload the FileSet once the data is copied since this is a long running task
      file_set.reload

      # attach downloaded file to FileSet stubbed out
      if CurationConcerns::FileSetActor.new(file_set, user).create_content(f)
        # send message to user on download success
        CurationConcerns.config.callback.run(:after_import_url_success, file_set, user)
        log.success!
      else
        CurationConcerns.config.callback.run(:after_import_url_failure, file_set, user)
        log.fail!(file_set.errors.full_messages.join(' '))
      end
    end
  end

  protected

    def copy_remote_file(file_set, f)
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
