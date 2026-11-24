# frozen_string_literal: true

RSpec.describe Hyrax::FlexibleSchemaValidators::ContextClassValidator do
  subject(:validator) { described_class.new(context) }
  let(:context) { Hyrax::FlexibleSchemaValidators::ValidationContext.new(profile: profile) }
  let(:warnings) { validator.violations.select(&:warning?).map(&:message) }
  let(:profile) { { 'properties' => { 'keyword_closed' => { 'available_on' => { 'class' => classes, 'context' => ['closed_context'] } } } } }

  let(:registry) { { collection_class_names: ['CollectionResource'], admin_set_class_names: ['AdminSetResource'], file_set_class_names: ['Hyrax::FileSet'] } }

  before do
    allow(Hyrax::ModelRegistry).to receive_messages(registry)
    validator.validate!
  end

  context 'when a property limited to a context is available on work classes' do
    let(:classes) { ['GenericWork'] }

    it 'does not warn' do
      expect(warnings).to be_empty
    end
  end

  context 'when a property limited to a context is available on collection, admin set or file set classes' do
    let(:classes) { %w[GenericWork CollectionResource AdminSetResource Hyrax::FileSet] }

    it 'warns, naming those classes' do
      expect(warnings).to contain_exactly(a_string_including('keyword_closed', 'CollectionResource', 'AdminSetResource', 'Hyrax::FileSet'))
    end
  end

  context 'when the registry and the profile write a class name differently' do
    let(:classes) { ['::CollectionResource', 'Hyrax::FileSet'] }
    let(:registry) { { collection_class_names: ['CollectionResource'], admin_set_class_names: [], file_set_class_names: ['::Hyrax::FileSet'] } }

    it 'warns, naming those classes as the profile does' do
      expect(warnings).to contain_exactly(a_string_including('keyword_closed', '::CollectionResource, Hyrax::FileSet'))
    end
  end

  context 'when a property is not limited to a context' do
    let(:profile) { { 'properties' => { 'keyword' => { 'available_on' => { 'class' => ['CollectionResource'] } } } } }

    it 'does not warn' do
      expect(warnings).to be_empty
    end
  end
end
