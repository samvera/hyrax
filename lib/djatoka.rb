require "httparty"
class Djatoka
  include HTTParty
  # base_uri 'http://salt-dev.stanford.edu:8080/adore-djatoka/resolver'
  base_uri "http://localhost:8080/adore-djatoka/resolver"
  default_params :url_ver => 'Z39.88-2004', :svc_val_fmt=> "info:ofi/fmt:kev:mtx:jpeg2000"
  
  # Uses Djatoka to scale the image from @source_url according to @scale_value
  # Accepts optional hash that will be passed through to djatoka as-is
  # scale_value is passed through to djatoka as svc.scale.
  # From the Djatoka docs:
  # svc.scale - Request specific output size by scaling extracted resource.
  # Option 1) Define a long-side dimension (e.g., svc.scale=96)
  # * Nearest resolution level, rounded up, is used for level parameter
  # * Uses the aspect ratio to calculate second value
  # Option 2) Define absolute w,h values (e.g. 1024,768)
  # * Images is scaled to the dimensions you specify.
  # * Value must be less than 2X current resolution
  # Option 3) Define a single dimension (e.g. 1024,0) with or without Level Parameter
  # * Uses the aspect ratio to calculate second value
  # Option 4) Use a single decimal scaling factor (e.g. 0.854)
  # * Current resolution = 1.0
  # * 50% Resolution = 0.5
  # * 150% Resolution = 1.5
  # * Value must be greater than 0 and less than 2
  def self.scale(source_url, scale_value, options={})
    options.merge!("svc.scale"=>scale_value)
    get_image(source_url, options)
  end
  
  # Uses Djatoka to retrieve a redion of the image from @source_url according to @scale_value
  # Accepts optional hash that will be passed through to djatoka as-is
  # scale_value is passed through to djatoka as svc.scale.
  # From the Djatoka docs:
  # svc.region - Y,X,H,W.
  # * Y is the down inset value (positive) from 0 on the y axis at the max image resolution.
  # * X is the right inset value (positive) from 0 on the x axis at the max image resolution.
  # * H is the height of the image provided as response.
  # * W is the width of the image provided as response.
  # * All values may either be absolute pixel values (e.g. 100,100,256,256), float values (e.g. 0.1,0.1,0.1,0.1), or a combination (e.g. 0.1,0.1,256,256).
  def self.region(source_url, region_value, options={})
    options.merge!("svc.region"=>region_value)
    get_image(source_url, options)
  end
  
  def self.get_image(source_url, options={})
    options.merge!({:svc_id => "info:lanl-repo/svc/getRegion", :rft_id=>source_url, "svc.format"=>"image/jpeg"})
    puts "get_region options: #{options.inspect}"
    get("", :query => options)
  end
  
end

# url_ver=Z39.88-2004
# &rft_id=http://memory.loc.gov/gmd/gmd433/g4330/g4330/np000066.jp2
# &svc_id=info:lanl-repo/svc/getRegion
# &svc_val_fmt=info:ofi/fmt:kev:mtx:jpeg2000
# &svc.format=image/jpeg
#     &svc.scale=600