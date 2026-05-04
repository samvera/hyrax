# frozen_string_literal: true

RSpec.describe Hyrax::FlexibleSchemaValidators::RedirectsValidator do
  subject(:validator) { described_class.new(profile: profile, errors: errors, warnings: warnings) }
  let(:errors) { [] }
  let(:warnings) { [] }

  let(:profile_with_redirects) do
    {
      'classes' => {
        'GenericWork' => {},
        'CollectionResource' => {}
      },
      'properties' => {
        'redirects' => {
          'type' => 'hash',
          'available_on' => { 'class' => %w[GenericWork CollectionResource] }
        }
      }
    }
  end

  let(:profile_without_redirects) do
    { 'properties' => { 'title' => {} } }
  end

  before do
    # In the engine spec environment, hyrax/file_set is registered as a
    # curation concern (see spec/support/flexible_metadata_setup.rb), which
    # propagates into work_class_names. Stub that scenario explicitly so
    # the validator is forced to actively exclude file_set rather than
    # relying on it being absent.
    allow(Hyrax::ModelRegistry).to receive(:work_class_names).and_return(['GenericWork', 'Hyrax::FileSet'])
    allow(Hyrax::ModelRegistry).to receive(:collection_class_names).and_return(['CollectionResource'])
    allow(Hyrax::ModelRegistry).to receive(:file_set_class_names).and_return(['Hyrax::FileSet'])
    allow(Hyrax::ModelRegistry).to receive(:admin_set_class_names).and_return(['Hyrax::AdministrativeSet'])
  end

  describe '#validate!' do
    context 'when Hyrax.config.redirects_enabled? is false' do
      before { allow(Hyrax.config).to receive(:redirects_enabled?).and_return(false) }

      context 'and the m3 profile has a `redirects` property' do
        let(:profile) { profile_with_redirects }

        it 'warns that the property will be ignored' do
          validator.validate!
          expect(warnings).to include(/redirects.*Hyrax\.config\.redirects_enabled\? is false/)
          expect(errors).to be_empty
        end
      end

      context 'and the m3 profile has no `redirects` property' do
        let(:profile) { profile_without_redirects }

        it 'is silent (no errors, no warnings)' do
          validator.validate!
          expect(errors).to be_empty
          expect(warnings).to be_empty
        end
      end
    end

    context 'when Hyrax.config.redirects_enabled? is true and Flipflop.redirects? is false' do
      before do
        allow(Hyrax.config).to receive(:redirects_enabled?).and_return(true)
        allow(Flipflop).to receive(:redirects?).and_return(false)
      end

      context 'and the m3 profile has a `redirects` property' do
        let(:profile) { profile_with_redirects }

        it 'warns that the property will be ignored' do
          validator.validate!
          expect(warnings).to include(/redirects.*:redirects feature flag is off/)
          expect(errors).to be_empty
        end
      end

      context 'and the m3 profile has no `redirects` property' do
        let(:profile) { profile_without_redirects }

        it 'is silent (the tenant has not opted in)' do
          validator.validate!
          expect(errors).to be_empty
          expect(warnings).to be_empty
        end
      end
    end

    context 'when both Hyrax.config.redirects_enabled? and Flipflop.redirects? are true' do
      before do
        allow(Hyrax.config).to receive(:redirects_enabled?).and_return(true)
        allow(Flipflop).to receive(:redirects?).and_return(true)
      end

      context 'and the m3 profile has no `redirects` property' do
        let(:profile) { profile_without_redirects }

        it 'records an error that the property is required' do
          validator.validate!
          expect(errors).to include(/m3 profile must declare a `redirects` property/)
        end
      end

      context 'and the m3 profile has `redirects` available on the required classes' do
        let(:profile) { profile_with_redirects }

        it 'is silent' do
          validator.validate!
          expect(errors).to be_empty
          expect(warnings).to be_empty
        end
      end

      context 'and the m3 profile has `redirects` available_on no work or collection class declared in the profile' do
        let(:profile) do
          {
            'classes' => { 'GenericWork' => {}, 'CollectionResource' => {} },
            'properties' => {
              'redirects' => {
                'type' => 'hash',
                'available_on' => { 'class' => ['SomeOtherClass'] }
              }
            }
          }
        end

        it 'records an error that the property must be available on a declared work or collection class' do
          validator.validate!
          expect(errors).to include(/`redirects`.*available on.*work or collection class/)
        end
      end

      context 'and the m3 profile has `redirects` available_on a FileSet (registered as a curation concern)' do
        let(:profile) do
          {
            'classes' => { 'Hyrax::FileSet' => {} },
            'properties' => {
              'redirects' => {
                'type' => 'hash',
                'available_on' => { 'class' => ['Hyrax::FileSet'] }
              }
            }
          }
        end

        it 'records an error that the property must be available on a declared work or collection class' do
          validator.validate!
          expect(errors).to include(/`redirects`.*available on.*work or collection class/)
        end
      end

      context 'and the m3 profile has `redirects` declared without `type: hash`' do
        let(:profile) do
          {
            'classes' => { 'GenericWork' => {}, 'CollectionResource' => {} },
            'properties' => {
              'redirects' => {
                'available_on' => { 'class' => %w[GenericWork CollectionResource] }
              }
            }
          }
        end

        it 'records an error that the property must declare type: hash' do
          validator.validate!
          expect(errors).to include(/`redirects`.*declare `type: hash`/)
        end
      end
    end
  end
end
