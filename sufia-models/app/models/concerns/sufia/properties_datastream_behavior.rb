module Sufia
  module PropertiesDatastreamBehavior
    extend ActiveSupport::Concern

    included do
      set_terminology do |t|
        t.root(:path=>"fields" )
        # This is where we put the user id of the object depositor -- impacts permissions/access controls
        t.depositor :index_as=>[:stored_searchable]
        # This is where we put the relative path of the file if submitted as a folder
        t.relative_path
        t.import_url path: 'importUrl', :index_as=>:symbol
      end
    end

    module ClassMethods
      def xml_template
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.fields
        end
        builder.doc
      end
    end

    def prefix
      ""
    end

  end
end
