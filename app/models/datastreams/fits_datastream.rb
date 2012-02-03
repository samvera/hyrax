class FitsDatastream < ActiveFedora::NokogiriDatastream
  include OM::XML::Document

  set_terminology do |t|
    t.root(:path => "fits", 
           :xmlns => "http://hul.harvard.edu/ois/xml/ns/fits/fits_output", 
           :schema => "http://hul.harvard.edu/ois/xml/xsd/fits/fits_output.xsd")
    t.identification {
      t.identity {
        t.format_label(:path=>{:attribute=>"format"})
        t.mime_type(:path=>{:attribute=>"mimetype"})
      }
    }
    t.fileinfo {
      t.file_size(:path=>"size")
      t.last_modified(:path=>"lastmodified")
      t.filename(:path=>"filename")
      t.original_checksum(:path=>"md5checksum")
    }
    t.filestatus { 
      t.well_formed(:path=>"well-formed")
      t.valid(:path=>"valid")
    }
    t.metadata {
      t.document {
        t.file_title(:path=>"title")
        t.file_author(:path=>"author")
        t.page_count(:path=>"pageCount")
      }
    }
    t.format_label(:proxy=>[:identification, :identity, :format_label])
    t.mime_type(:proxy=>[:identification, :identity, :mime_type])
    t.file_size(:proxy=>[:fileinfo, :file_size])
    t.last_modified(:proxy=>[:fileinfo, :last_modified])
    t.filename(:proxy=>[:fileinfo, :filename])
    t.original_checksum(:proxy=>[:fileinfo, :original_checksum])
    t.well_formed(:proxy=>[:filestatus, :well_formed])
    t.valid(:proxy=>[:filestatus, :valid])
    t.file_title(:proxy=>[:metadata, :document, :file_title])
    t.file_author(:proxy=>[:metadata, :document, :file_author])
    t.page_count(:proxy=>[:metadata, :document, :page_count])
  end

  def self.xml_template
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.fits(:xmlns => 'http://hul.harvard.edu/ois/xml/ns/fits/fits_output',
               'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
               'xsi:schemaLocation' =>
    "http://hul.harvard.edu/ois/xml/ns/fits/fits_output
    http://hul.harvard.edu/ois/xml/xsd/fits/fits_output.xsd",
               :version => "0.6.0",
               :timestamp => "1/25/12 11:04 AM") {
        xml.identification {
          xml.identity(:format => '', :mimetype => '', 
                       :toolname => 'FITS', :toolversion => '') {
            xml.tool(:toolname => '', :toolversion => '')
            xml.version(:toolname => '', :toolversion => '')
            xml.externalIdentifier(:toolname => '', :toolversion => '')
          }
        }
        xml.fileinfo {
          xml.size(:toolname => '', :toolversion => '')
          xml.creatingApplicatioName(:toolname => '', :toolversion => '',
                                     :status => '')
          xml.lastmodified(:toolname => '', :toolversion => '', :status => '')
          xml.filepath(:toolname => '', :toolversion => '', :status => '')
          xml.filename(:toolname => '', :toolversion => '', :status => '')
          xml.md5checksum(:toolname => '', :toolversion => '', :status => '')
          xml.fslastmodified(:toolname => '', :toolversion => '', :status => '')
        }
        xml.filestatus {
          xml.tag! "well-formed", :toolname => '', :toolversion => '', :status => ''
          xml.valid(:toolname => '', :toolversion => '', :status => '')
        }
        xml.metadata {
          xml.document {
            xml.title(:toolname => '', :toolversion => '', :status => '')
            xml.author(:toolname => '', :toolversion => '', :status => '')
            xml.pageCount(:toolname => '', :toolversion => '')
            xml.isTagged(:toolname => '', :toolversion => '')
            xml.hasOutline(:toolname => '', :toolversion => '')
            xml.hasAnnotations(:toolname => '', :toolversion => '')
            xml.isRightsManaged(:toolname => '', :toolversion => '', 
                                :status => '')
            xml.isProtected(:toolname => '', :toolversion => '')
            xml.hasForms(:toolname => '', :toolversion => '', :status => '')
          }
        }
      }
    end
    builder.doc
  end
end
