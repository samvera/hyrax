module Sufia
  module PropertiesDatastreamBehavior
    extend ActiveSupport::Concern

    included do
      has_many_versions
      set_terminology do |t|
        t.root(path: "fields")
        # This is where we put the user id of the object depositor -- impacts permissions/access controls
        t.depositor index_as: [:symbol, :stored_searchable]
        # This is where we put the relative path of the file if submitted as a folder
        t.relative_path
        t.import_url path: 'importUrl', index_as: :symbol
        t.proxy_depositor path: 'proxyDepositor', index_as: :symbol
        # This value is set when a user indicates they are depositing this for someone else
        t.on_behalf_of path: 'onBehalfOf', index_as: :symbol
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

  def save
    super.tap do |passing|
      create_version if passing
    end
  end
end
