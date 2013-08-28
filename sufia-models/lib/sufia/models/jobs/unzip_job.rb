class UnzipJob < ActiveFedoraPidBasedJob
  def queue_name
    :unzip
  end

  def run
    Zip::Archive.open_buffer(object.content.content) do |archive|
      archive.each do |f|
        if f.directory?
          create_directory(f)
        else
          create_file(f)
        end
      end
    end
  end

  protected

  # Creates a GenericFile object based on +file+
  # @param file [Zip::File]
  def create_file(file)
    @generic_file = GenericFile.new
    @generic_file.batch_id = object.batch.pid
    @generic_file.add_file(file.read, 'content', file.name)
    @generic_file.apply_depositor_metadata(object.edit_users.first)
    @generic_file.date_uploaded = Time.now.ctime
    @generic_file.date_modified = Time.now.ctime
    @generic_file.save
  end
  
  # Creates representation of directory corresponding to +file+
  # Default behavior: _do nothing_
  # @param file [Zip::File]
  def create_directory(file)
  end

end
