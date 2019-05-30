
RSpec.describe Hyrax::Indexing::DefaultDescriptors do
  describe ".searchable" do
    subject(:descriptor) { described_class.searchable }

    it "constructs a Descriptor object" do
      expect(descriptor).to be_a Hyrax::Indexing::Descriptor
    end
  end

  describe ".dateable" do
    subject(:descriptor) { described_class.dateable }

    it "constructs a Descriptor object" do
      expect(descriptor).to be_a Hyrax::Indexing::Descriptor
    end
  end

  describe ".displayable" do
    subject(:descriptor) { described_class.displayable }

    it "constructs a Descriptor object" do
      expect(descriptor).to be_a Hyrax::Indexing::Descriptor
    end
  end

  describe ".unstemmed_searchable" do
    subject(:descriptor) { described_class.unstemmed_searchable }

    it "constructs a Descriptor object" do
      expect(descriptor).to be_a Hyrax::Indexing::Descriptor
    end
  end

  describe ".simple" do
    subject(:descriptor) { described_class.simple }

    it "constructs a Descriptor object" do
      expect(descriptor).to be_a Hyrax::Indexing::Descriptor
    end
  end

  describe ".searchable_field_definition" do
    it "generates field definitions from field types" do
      expect(described_class.searchable_field_definition.call(:boolean)).to eq([:boolean, :indexed, :multivalued])
      expect(described_class.searchable_field_definition.call(:text)).to eq([:text_en, :indexed, :multivalued])
    end
  end

  describe ".stored_searchable_field_definition" do
    it "generates field definitions from field types" do
      expect(described_class.stored_searchable_field_definition.call(:boolean)).to eq([:boolean, :indexed, :stored])
      expect(described_class.stored_searchable_field_definition.call(:text)).to eq([:text_en, :indexed, :stored, :multivalued])
      expect(described_class.stored_searchable_field_definition.call(:date)).to eq([:date, :indexed, :stored, :multivalued])
    end
  end

  describe ".iso8601_date" do
    it "generates a timestamp from a date or time object" do
      new_date = Date.new
      # rubocop:disable Rails/Date
      expect(described_class.iso8601_date(new_date)).to eq new_date.to_time.strftime('%Y-%m-%dT%H:%M:%SZ')
      # rubocop:enable Rails/Date

      new_time = Time.new.utc
      expect(described_class.iso8601_date(new_time)).to eq new_time.strftime('%Y-%m-%dT%H:%M:%SZ')

      expect(described_class.iso8601_date("01/01/1970")).to eq "1970-01-01T00:00:00Z"
    end

    it "raises an error if a non-date and non-time object is passed" do
      expect { described_class.iso8601_date("test") }.to raise_error(ArgumentError, "Unable to parse `test' as a date-time object")
    end
  end

  describe ".dateable_converter" do
    it "generates a timestamp from a date or time object" do
      expect(described_class.dateable_converter.call(:noop).call("01/01/1970")).to eq "1970-01-01T00:00:00Z"
    end

    it "returns nil if a non-date and non-time object is passed" do
      expect(described_class.dateable_converter.call(:noop).call("test")).to be nil
    end
  end
end
