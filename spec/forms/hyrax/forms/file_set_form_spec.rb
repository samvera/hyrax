# frozen_string_literal: true

RSpec.describe Hyrax::Forms::FileSetForm do
  subject(:form) { described_class.new(file_set) }
  let(:file_set) { Hyrax::FileSet.new }

  describe '.fields' do
    # rubocop:disable RSpec/RepeatedDescription (these aren't repeated, rubocop)
    its(:fields) { is_expected.to have_key('based_near') }
    its(:fields) { is_expected.to have_key('creator') }
    its(:fields) { is_expected.to have_key('contributor') }
    its(:fields) { is_expected.to have_key('date_created') }
    its(:fields) { is_expected.to have_key('description') }
    its(:fields) { is_expected.to have_key('identifier') }
    its(:fields) { is_expected.to have_key('keyword') }
    its(:fields) { is_expected.to have_key('language') }
    its(:fields) { is_expected.to have_key('license') }
    its(:fields) { is_expected.to have_key('publisher') }
    its(:fields) { is_expected.to have_key('related_url') }
    its(:fields) { is_expected.to have_key('subject') }
    its(:fields) { is_expected.to have_key('title') }
    its(:fields) { is_expected.to have_key('visibility') }
    its(:fields) { is_expected.to have_key('transcript_ids') }
    # rubocop:enable RSpec/RepeatedDescription
  end

  describe '.required_fields' do
    it 'lists the fields tagged required' do
      expect(described_class.required_fields)
        .to contain_exactly(:title, :creator)
    end
  end

  describe '#embargo_release_date' do
    context 'without an embargo' do
      it 'is nil' do
        expect { form.prepopulate! }
          .not_to change { form.embargo_release_date }
          .from(nil)
      end
    end
  end

  describe '#lease_expiration_date' do
    context 'without a lease' do
      it 'is nil' do
        expect { form.prepopulate! }
          .not_to change { form.lease_expiration_date }
          .from(nil)
      end
    end
  end

  describe '#required' do
    it 'requires title' do
      expect(form.required?(:title)).to eq true
    end
  end

  # redirects is a Work/Collection concern; FileSets have no `redirects`
  # attribute. The redirects form property must therefore not be declared on the
  # FileSet form — otherwise Reform reads `redirects` off the FileSet model while
  # building the form twin (on validate/prepopulate) and raises NoMethodError.
  # This regressed when the redirects property was declared on the base
  # ResourceForm (which FileSetForm inherits) rather than on the work/collection
  # forms. Requires HYRAX_REDIRECTS_ENABLED=true at load so the wiring is active.
  context 'when the redirects feature is enabled', if: Hyrax.config.redirects_enabled? do
    it 'does not declare a redirects property on the FileSet form' do
      expect(described_class.definitions.keys).not_to include('redirects')
    end

    it 'validates without reading a redirects attribute off the FileSet' do
      expect { form.validate(title: ['A file']) }.not_to raise_error
    end
  end

  describe '#visibility_after_embargo' do
    context 'without an embargo' do
      it 'is nil' do
        expect { form.prepopulate! }
          .not_to change { form.visibility_after_embargo }
          .from(nil)
      end
    end
  end

  describe '#visibility_during_embargo' do
    context 'without an embargo' do
      it 'is nil' do
        expect { form.prepopulate! }
          .not_to change { form.visibility_during_embargo }
          .from(nil)
      end
    end
  end

  describe '#visibility_after_lease' do
    context 'without a lease' do
      it 'is nil' do
        expect { form.prepopulate! }
          .not_to change { form.visibility_after_lease }
          .from(nil)
      end
    end
  end

  describe '#visibility_during_lease' do
    context 'without a lease' do
      it 'is nil' do
        expect { form.prepopulate! }
          .not_to change { form.visibility_during_lease }
          .from(nil)
      end
    end
  end
end
