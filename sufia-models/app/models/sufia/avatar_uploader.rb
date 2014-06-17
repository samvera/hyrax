class Sufia::AvatarUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  include CarrierWave::Compatibility::Paperclip

  attr_accessor :original_size

  before :cache, :get_original_file_size
  
  process convert: 'png'
  
  version :medium do
    process resize_to_limit: [300, 300]
    
  end

  version :thumb do
    process resize_to_limit: [100, 100]
  end

  def default_url
    "/assets/missing_#{version_name}.png"
  end

  def extension_white_list
    %w(jpg jpeg png gif bmp tif tiff)
  end

  def get_original_file_size file
    @original_size = file.size
  end

end
