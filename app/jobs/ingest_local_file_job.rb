class IngestLocalFileJob
  def queue_name
    :ingest
  end

  attr_accessor :directory, :filename, :user_key, :generic_file_id

  def initialize(generic_file_id, directory, filename, user_key)
    self.generic_file_id = generic_file_id
    self.directory = directory
    self.filename = filename 
    self.user_key = user_key
  end

  def run
    filedata = File.new( File.join(directory, filename) )
    generic_file = GenericFile.find(generic_file_id)
    user = User.find_by_user_key(user_key)
    raise "Unable to find user for #{user_key}" unless user
    
    # virus check
    virus_stat = Sufia::GenericFile::Actions.virus_check(filedata)
    raise "Virus checking did not pass for #{File.basename(filedata.path)} status = #{virus_stat}" unless virus_stat == 0
    
    generic_file.label = File.basename(filename)
    generic_file.add_file(File.open(File.join(directory, filename)), 'content', generic_file.label)
    generic_file.record_version_committer(user)
    generic_file.save!

    #Sufia.queue.push(UnzipJob.new(generic_file.pid)) if generic_file.content.mimeType == 'application/zip'
    Sufia.queue.push(ContentDepositEventJob.new(generic_file.pid, user_key))
    FileUtils.rm([File.join(directory, filename)])
  end
end
