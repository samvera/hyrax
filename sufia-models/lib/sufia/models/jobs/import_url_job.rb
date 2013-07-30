require 'net/https'
require 'uri'
require 'tempfile'

class ImportUrlJob < ActiveFedoraPidBasedJob

  def queue_name
    :import_url
  end

  def run
    f = Tempfile.new(self.pid)
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
    job_user = User.batchuser()
    user = User.find_by_user_key(generic_file.depositor)
    # check for virus
    if Sufia::GenericFile::Actions.virus_check(f) != 0
      message = "The file (#{File.basename(uri.path)}) was unable to be imported because it contained a virus."
      job_user.send_message(user, message, 'File Import Error') 
      return
    end

    f.rewind
    # attach downloaded file to generic file stubbed out
    Sufia::GenericFile::Actions.create_content(generic_file, f, File.basename(uri.path), 'content', user)
    # add message to user for downloaded file
    message = "The file (#{File.basename(uri.path)}) was successfully imported." 
    job_user.send_message(user, message, 'File Import') 
 
  ensure
    f.close
    f.unlink
  end
end
