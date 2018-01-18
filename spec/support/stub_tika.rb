# frozen_string_literal: true

RSpec.shared_context "Tika output" do
  let(:tika_tiff_output) do
    <<-JSON
      {"Bits Per Sample":"8 8 8 bits/component/pixel","Compression":"Uncompressed","Content-Length":"4218","Content-Type":"image/tiff","Creation-Date":"2014-12-03T12:40:50","Date/Time":"2014:12:03 12:40:50","Document Name":"color_200.tif","File Modified Date":"Thu Jul 13 17:34:57 PDT 2017","File Name":"example.tif20170713-88893-1cirjkm","File Size":"196882 bytes","Fill Order":"Normal","Image Height":"287 pixels","Image Width":"200 pixels","Inter Color Profile":"[560 bytes]","Last-Modified":"2014-12-03T12:40:50","Last-Save-Date":"2014-12-03T12:40:50","Make":"Phase One","Model":"P65+","Orientation":"Top, left side (Horizontal / normal)","Photometric Interpretation":"RGB","Planar Configuration":"Chunky (contiguous for each subsampling pixel)","Primary Chromaticities":"2748779008/4294967295 1417339264/4294967295 1288490240/4294967295 2576980480/4294967295 644245120/4294967295 257698032/4294967295","Resolution Unit":"Inch","Rows Per Strip":"13 rows/strip","Samples Per Pixel":"3 samples/pixel","Software":"Adobe Photoshop CS5.1 Macintosh","Strip Byte Counts":"7800 7800 7800 7800 7800 7800 7800 7800 7800 7800 7800 7800 7800 7800 7800 7800 7800 7800 7800 7800 7800 7800 600 bytes","Strip Offsets":"[23 longs]","Unknown tag (0x0129)":"0 1","Unknown tag (0x02bc)":"[14622 shorts]","Unknown tag (0x8649)":"[8822 shorts]","White Point":"1343036288/4294967295 1413044224/4294967295","X Resolution":"1120 dots per inch","X-Parsed-By":["org.apache.tika.parser.DefaultParser","org.apache.tika.parser.image.TiffParser"],"Y Resolution":"1120 dots per inch","date":"2014-12-03T12:40:50","dcterms:created":"2014-12-03T12:40:50","dcterms:modified":"2014-12-03T12:40:50","meta:creation-date":"2014-12-03T12:40:50","meta:save-date":"2014-12-03T12:40:50","modified":"2014-12-03T12:40:50","resourceName":"example.tif20170713-88893-1cirjkm","tiff:BitsPerSample":"8","tiff:ImageLength":"287","tiff:ImageWidth":"200","tiff:Make":"Phase One","tiff:Model":"P65+","tiff:Orientation":"1","tiff:ResolutionUnit":"Inch","tiff:SamplesPerPixel":"3","tiff:Software":"Adobe Photoshop CS5.1 Macintosh","tiff:XResolution":"1120.0","tiff:YResolution":"1120.0"}
    JSON
  end
  let(:tika_png_output) do
    <<-JSON
      {"Chroma BackgroundColor":"red=255, green=255, blue=255", "Chroma BlackIsZero":"true", "Chroma ColorSpaceType":"RGB", "Chroma NumChannels":"4", "Compression CompressionTypeName":"deflate", "Compression Lossless":"true", "Compression NumProgressiveScans":"1", "Content-Length":"4218", "Content-Type":"image/png", "Data BitsPerSample":"8 8 8 8", "Data PlanarConfiguration":"PixelInterleaved", "Data SampleFormat":"UnsignedIntegral", "Dimension ImageOrientation":"Normal", "Dimension PixelAspectRatio":"1.0", "Document ImageModificationTime":"year=2009, month=11, day=4, hour=9, minute=6, second=44", "IHDR":"width=50, height=50, bitDepth=8, colorType=RGBAlpha, compressionMethod=deflate, filterMethod=adaptive, interlaceMethod=none", "Transparency Alpha":"nonpremultipled", "X-Parsed-By":["org.apache.tika.parser.DefaultParser", "org.apache.tika.parser.image.ImageParser"], "bKGD bKGD_RGB":"red=255, green=255, blue=255", "height":"50", "resourceName":"world.png", "tIME":"year=2009, month=11, day=4, hour=9, minute=6, second=44", "tiff:BitsPerSample":"8 8 8 8", "tiff:ImageLength":"50", "tiff:ImageWidth":"50", "width":"50"}
    JSON
  end
  let(:tika_jpg_output) do
    <<-JSON
      {"Component 1":"Y component: Quantization table 0, Sampling factors 2 horiz/2 vert", "Component 2":"Cb component: Quantization table 1, Sampling factors 1 horiz/1 vert", "Component 3":"Cr component: Quantization table 1, Sampling factors 1 horiz/1 vert", "Compression Type":"Baseline", "Content-Length":"113885", "Content-Type":"image/jpeg", "Data Precision":"8 bits", "Exif Image Height":"465 pixels", "Exif Image Width":"512 pixels", "File Modified Date":"Wed Jan 10 11:21:41 CST 2018", "File Name":"image.jpg", "File Size":"113885 bytes", "Image Height":"465 pixels", "Image Width":"512 pixels", "Number of Components":"3", "Orientation":"Top, left side (Horizontal / normal)", "Resolution Unit":"Inch", "Resolution Units":"inch", "X Resolution":"72 dots", "X-Parsed-By":["org.apache.tika.parser.DefaultParser", "org.apache.tika.parser.jpeg.JpegParser"], "Y Resolution":"72 dots", "resourceName":"image.jpg", "tiff:BitsPerSample":"8", "tiff:ImageLength":"465", "tiff:ImageWidth":"512", "tiff:Orientation":"1", "tiff:ResolutionUnit":"Inch", "tiff:XResolution":"72.0", "tiff:YResolution":"72.0"}
    JSON
  end
  let(:tika_txt_output) do
    <<-JSON
      {"Content-Encoding":"ISO-8859-1", "Content-Length":"6", "Content-Type":"text/plain; charset=ISO-8859-1", "X-Parsed-By":["org.apache.tika.parser.DefaultParser", "org.apache.tika.parser.txt.TXTParser"], "resourceName":"small_file.txt"}
    JSON
  end
  let(:tika_output) { tika_tiff_output }
end

RSpec.configure do |config|
  config.include_context "Tika output"
  config.before do
    ruby_mock = instance_double(RubyTikaApp, to_json: tika_output)
    allow(RubyTikaApp).to receive(:new).and_return(ruby_mock)
  end
end
