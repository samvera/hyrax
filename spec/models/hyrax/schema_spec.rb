# frozen_string_literal: true

RSpec.describe Hyrax::Schema do
  let(:resource_class) do
    Class.new(Valkyrie::Resource)
  end

  describe 'including' do
    it 'applies the specified schema' do
      expect { resource_class.include(Hyrax::Schema(:core_metadata)) }
        .to change { resource_class.attribute_names }
        .to include(:title, :date_uploaded, :date_modified, :depositor)
    end

    it 'raises for an missing schema' do
      expect { resource_class.include(Hyrax::Schema(:FAKE_SCHEMA)) } .to raise_error ArgumentError
    end
  end
end
