# frozen_string_literal: true

# This uses app/services/hydra_editor/field_metadata_service.rb, which calls
#   #reflect_on_association on the FileSet class. This is an ActiveFedora-specific
#   method that doesn't translate to Valkyrie Work behavior.
RSpec.describe Hyrax::Forms::FileSetEditForm, :active_fedora do
  subject { described_class.new(FileSet.new) }

  describe '#terms' do
    it 'returns a list' do
      expect(subject.terms).to eq(
        [:resource_type, :title, :creator, :contributor, :description, :keyword,
         :license, :publisher, :date_created, :subject, :language, :identifier,
         :based_near, :related_url,
         :visibility_during_embargo, :visibility_after_embargo, :embargo_release_date,
         :visibility_during_lease, :visibility_after_lease, :lease_expiration_date,
         :visibility]
      )
    end

    it "doesn't contain fields that users shouldn't be allowed to edit" do
      # date_uploaded is reserved for the original creation date of the record.
      expect(subject.terms).not_to include(:date_uploaded)
    end
  end

  it 'initializes multivalued fields' do
    expect(subject.title).to eq ['']
  end

  describe '.model_attributes' do
    let(:params) do
      ActionController::Parameters.new(
        title: ['foo'],
        "visibility" => "on-campus",
        "visibility_during_embargo" => "restricted",
        "embargo_release_date" => "2015-10-21",
        "visibility_after_embargo" => "open",
        "visibility_during_lease" => "open",
        "lease_expiration_date" => "2015-10-21",
        "visibility_after_lease" => "restricted"
      )
    end

    subject { described_class.model_attributes(params) }

    it 'changes only the title' do
      expect(subject['title']).to eq ['foo']
      expect(subject['visibility']).to eq('on-campus')
      expect(subject['visibility_during_embargo']).to eq('restricted')
      expect(subject['visibility_after_embargo']).to eq('open')
      expect(subject['embargo_release_date']).to eq('2015-10-21')
      expect(subject['visibility_during_lease']).to eq('open')
      expect(subject['visibility_after_lease']).to eq('restricted')
      expect(subject['lease_expiration_date']).to eq('2015-10-21')
    end
  end
end
