# frozen_string_literal: true

RSpec.describe Hyrax::FlexibleSchemaValidators::RedirectsValidator do
  subject(:validator) { described_class.new(profile: profile, errors: errors, warnings: warnings) }
  let(:errors) { [] }
  let(:warnings) { [] }

  let(:profile_with_redirects) do
    {
      'classes' => { 'GenericWork' => {}, 'CollectionResource' => {} },
      'properties' => {
        'redirects' => {
          'available_on' => { 'class' => %w[GenericWork CollectionResource] }
        }
      }
    }
  end

  before do
    allow(Hyrax.config).to receive(:registered_curation_concern_types).and_return(['GenericWork'])
  end

  let(:profile_without_redirects) do
    { 'properties' => { 'title' => {} } }
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

        it 'errors that the property is required' do
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

      context 'and the m3 profile has `redirects` with an adopter-registered work class (Resource-suffixed)' do
        let(:profile) do
          {
            'classes' => { 'GenericWorkResource' => {} },
            'properties' => {
              'redirects' => { 'available_on' => { 'class' => ['GenericWorkResource'] } }
            }
          }
        end

        it 'is silent (Resource suffix is accepted alongside the abstract name)' do
          validator.validate!
          expect(errors).to be_empty
        end
      end

      context 'and the m3 profile lists a class in available_on.class that is not declared in this profile' do
        let(:profile) do
          {
            'classes' => { 'GenericWork' => {} },
            'properties' => {
              'redirects' => { 'available_on' => { 'class' => ['SomeOtherWork'] } }
            }
          }
        end

        it 'errors (the class is not declared in this profile)' do
          validator.validate!
          expect(errors).to include(/declared in this profile/)
        end
      end

      context 'and the m3 profile has `redirects` available only on a non-work, non-collection class declared in the profile' do
        let(:profile) do
          {
            'classes' => { 'Hyrax::FileSet' => {} },
            'properties' => {
              'redirects' => { 'available_on' => { 'class' => ['Hyrax::FileSet'] } }
            }
          }
        end

        it 'errors that the property must be available on at least one work or collection class' do
          validator.validate!
          expect(errors).to include(/work or collection class/)
        end
      end

      context 'and the m3 profile has `redirects` with an empty available_on.class' do
        let(:profile) do
          {
            'classes' => { 'GenericWork' => {} },
            'properties' => {
              'redirects' => { 'available_on' => { 'class' => [] } }
            }
          }
        end

        it 'errors that the property must be available on at least one work or collection class' do
          validator.validate!
          expect(errors).to include(/work or collection class/)
        end
      end

      context 'and the m3 profile has `redirects` with available_on entirely missing' do
        let(:profile) do
          {
            'classes' => { 'GenericWork' => {} },
            'properties' => {
              'redirects' => { 'cardinality' => { 'minimum' => 0 } }
            }
          }
        end

        it 'errors that the property must be available on at least one work or collection class' do
          validator.validate!
          expect(errors).to include(/work or collection class/)
        end
      end
    end
  end
end
