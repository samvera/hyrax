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
  let(:tika_wav_output) do
    <<-JSON
      {"Content-Length":"784512","Content-Type":"audio/x-wav","X-Parsed-By":["org.apache.tika.parser.DefaultParser","org.apache.tika.parser.audio.AudioParser"],"bits":"16","channels":"2","encoding":"PCM_SIGNED","resourceName":"piano_note.wav","samplerate":"44100.0","xmpDM:audioSampleRate":"44100","xmpDM:audioSampleType":"16Int"}
    JSON
  end
  let(:tika_pdf_output) do
    <<-JSON
      {"Author":"carlos","Content-Length":"218882","Content-Type":"application/pdf","Creation-Date":"2010-10-09T10:29:55Z","Last-Modified":"2010-10-09T10:29:55Z","Last-Save-Date":"2010-10-09T10:29:55Z","X-Parsed-By":["org.apache.tika.parser.DefaultParser","org.apache.tika.parser.pdf.PDFParser"],"access_permission:assemble_document":"true","access_permission:can_modify":"true","access_permission:can_print":"true","access_permission:can_print_degraded":"true","access_permission:extract_content":"true","access_permission:extract_for_accessibility":"true","access_permission:fill_in_form":"true","access_permission:modify_annotations":"true","created":"Sat Oct 09 06:29:55 EDT 2010","creator":"carlos","date":"2010-10-09T10:29:55Z","dc:creator":"carlos","dc:format":"application/pdf; version\u003d1.4","dc:title":"Microsoft Word - sample.pdf.docx","dcterms:created":"2010-10-09T10:29:55Z","dcterms:modified":"2010-10-09T10:29:55Z","meta:author":"carlos","meta:creation-date":"2010-10-09T10:29:55Z","meta:save-date":"2010-10-09T10:29:55Z","modified":"2010-10-09T10:29:55Z","pdf:PDFVersion":"1.4","pdf:encrypted":"false","producer":"GPL Ghostscript 8.15","resourceName":"hyrax_test4.pdf","title":"Microsoft Word - sample.pdf.docx","xmp:CreatorTool":"PScript5.dll Version 5.2.2","xmpTPg:NPages":"1"}
    JSON
  end
end

RSpec.configure do |config|
  config.include_context "Tika output"
  config.before do
    allow(RubyTikaApp).to receive(:new) do |file_path|
      ext = File.extname(file_path)
      case ext
      when ".tif"
        instance_double(RubyTikaApp, to_json: tika_tiff_output)
      when ".png"
        instance_double(RubyTikaApp, to_json: tika_png_output)
      when ".jpg"
        instance_double(RubyTikaApp, to_json: tika_jpg_output)
      when ".txt"
        instance_double(RubyTikaApp, to_json: tika_txt_output)
      when ".wav"
        instance_double(RubyTikaApp, to_json: tika_wav_output)
      when ".pdf"
        instance_double(RubyTikaApp, to_json: tika_pdf_output)
      else
        instance_double(RubyTikaApp, to_json: tika_tiff_output)
      end
    end
  end
end
