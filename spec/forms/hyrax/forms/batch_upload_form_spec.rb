# frozen_string_literal: true

# This uses app/services/hydra_editor/field_metadata_service.rb, which calls
#   #reflect_on_association on the Work class. This is an ActiveFedora-specific
#   method that doesn't translate to Valkyrie Work behavior.
RSpec.describe Hyrax::Forms::BatchUploadForm, :active_fedora do
  let(:model) { GenericWork.new }
  let(:controller) { instance_double(Hyrax::BatchUploadsController) }
  let(:form) { described_class.new(model, ability, controller) }
  let(:ability) { Ability.new(user) }
  let(:user) { build(:user, display_name: 'Jill Z. User') }

  before do
    allow(Valkyrie.config).to receive(:resource_class_resolver).and_return(->(_name) { model.class })
    allow(Hyrax.config).to receive(:use_valkyrie?).and_return(false)
  end

  describe "#primary_terms" do
    subject { form.primary_terms }

    it { is_expected.to eq [:creator, :rights_statement] }
    it { is_expected.not_to include(:title) }
  end

  describe "#secondary_terms" do
    subject { form.secondary_terms }

    it { is_expected.not_to include(:title) } # title is per file, not per form
  end

  describe ".model_name" do
    subject { described_class.model_name }

    it "has a route_key" do
      expect(subject.route_key).to eq 'batch_uploads'
    end
    it "has a param_key" do
      expect(subject.param_key).to eq 'batch_upload_item'
    end
  end

  describe "#to_model" do
    subject { form.to_model }

    it "returns itself" do
      expect(subject.to_model).to be_kind_of described_class
    end
  end

  describe "#terms" do
    subject { form.terms }

    it do
      is_expected.to eq [:alternative_title,
                         :creator,
                         :contributor,
                         :description,
                         :abstract,
                         :keyword,
                         :license,
                         :rights_statement,
                         :access_right,
                         :rights_notes,
                         :publisher,
                         :date_created,
                         :subject,
                         :language,
                         :identifier,
                         :based_near,
                         :related_url,
                         :bibliographic_citation,
                         :representative_id,
                         :thumbnail_id,
                         :rendering_ids,
                         :files,
                         :visibility_during_embargo,
                         :embargo_release_date,
                         :visibility_after_embargo,
                         :visibility_during_lease,
                         :lease_expiration_date,
                         :visibility_after_lease,
                         :visibility,
                         :ordered_member_ids,
                         :source,
                         :in_works_ids,
                         :member_of_collection_ids,
                         :admin_set_id]
    end
  end
end

RSpec.describe Hyrax::Forms::BatchUploadForm, '#required_fields for a flexible payload' do
  let(:profile_fields) do
    { 'title' => { required: true, primary: true, display: true },
      'profile_only_field' => { required: true, primary: false, display: true } }
  end

  let(:schema_loader) do
    loader = instance_double(Hyrax::M3SchemaLoader)
    allow(loader).to receive(:current_version).and_return(1)
    allow(loader).to receive(:index_rules_for).and_return({})
    allow(loader).to receive(:form_definitions_for) { profile_fields }
    allow(loader).to receive(:attributes_for) do
      profile_fields.keys.each_with_object({}) do |name, attrs|
        attrs[name.to_sym] = Valkyrie::Types::Array.of(Valkyrie::Types::String)
      end
    end
    loader
  end

  let(:work_class) do
    klass = Class.new(Hyrax::Work) do
      def self.name
        'TestBatchFlexibleWork'
      end
    end
    klass.acts_as_flexible_resource
    klass
  end

  let(:form) { described_class.allocate.tap { |f| f.payload_concern = 'TestBatchFlexibleWork' } }

  before do
    allow(Hyrax.config).to receive(:flexible?).and_return(true)
    allow(Hyrax.config).to receive(:use_valkyrie?).and_return(true)
    allow(Hyrax::Schema).to receive(:m3_schema_loader).and_return(schema_loader)
    allow(Hyrax::FlexibleSchema).to receive(:current_schema_id).and_return(1)
    stub_const('TestBatchFlexibleWork', work_class)
    stub_const('TestBatchFlexibleWorkForm', Class.new(Hyrax::Forms::ResourceForm(work_class)))
    allow(Valkyrie.config).to receive(:resource_class_resolver).and_return(->(_name) { work_class })
  end

  after do
    Hyrax.config.flexible_classes.delete('TestBatchFlexibleWork')
  end

  it "requires the fields the payload's profile requires" do
    expect(form.required_fields).to include(:title, :profile_only_field)
  end

  context "when the batch's admin set has contexts" do
    let(:context_field) { { 'context_only_field' => { required: true, primary: false, display: true } } }

    before do
      allow(schema_loader).to receive(:form_definitions_for) do |**kwargs|
        Array(kwargs[:contexts]).include?('special') ? profile_fields.merge(context_field) : profile_fields
      end
      allow(schema_loader).to receive(:attributes_for) do
        profile_fields.merge(context_field).keys.each_with_object({}) do |name, attrs|
          attrs[name.to_sym] = Valkyrie::Types::Array.of(Valkyrie::Types::String)
        end
      end
      allow(Hyrax.query_service).to receive(:find_by).and_call_original
      allow(Hyrax.query_service).to receive(:find_by).with(id: 'special-admin-set').and_return(double(contexts: ['special']))
      allow(form).to receive(:model).and_return(double(admin_set_id: 'special-admin-set'))
    end

    it "requires the fields the admin set's context requires" do
      expect(form.required_fields).to include(:context_only_field)
    end
  end
end
