# frozen_string_literal: true

RSpec.describe Hyrax::PermissionLevelsHelper do
  before { @old_locale = I18n.locale }
  after { I18n.locale = @old_locale } # rubocop:disable RSpec/InstanceVariable

  describe '#configured_permission_levels' do
    it 'gives a hash with default values' do
      expect(configured_permission_levels)
        .to eq('Edit access' => 'edit', 'View/Download' => 'read')
    end

    context 'overridden as empty' do
      before do
        allow(Hyrax.config).to receive(:permission_levels).and_return({})
      end

      it 'gives an empty hash' do
        expect(configured_permission_levels).to eq({})
      end
    end

    context 'overridden with values' do
      let(:values) do
        { 'View/Download' => 'read', 'moomin' => 'edit' }
      end

      before do
        allow(Hyrax.config).to receive(:permission_levels).and_return(values)
      end

      it 'gives i18nized hash' do
        expect { I18n.locale = :de }
          .to change { configured_permission_levels }
          .from('Edit access' => 'edit', 'View/Download' => 'read')
      end
    end
  end

  describe '#configured_owner_permission_levels' do
    it 'gives a hash with default values' do
      expect(configured_owner_permission_levels)
        .to eq('Edit access' => 'edit')
    end

    context 'overridden as empty' do
      before do
        allow(Hyrax.config).to receive(:owner_permission_levels).and_return({})
      end

      it 'gives an empty hash' do
        expect(configured_owner_permission_levels).to eq({})
      end
    end

    context 'overridden with values' do
      let(:values) do
        { 'moomin' => 'edit' }
      end

      before do
        allow(Hyrax.config).to receive(:owner_permission_levels).and_return(values)
      end

      it 'gives i18nized hash' do
        expect { I18n.locale = :de }
          .to change { configured_owner_permission_levels }
          .from('Edit access' => 'edit')
      end
    end
  end

  describe '#configured_permission_options' do
    it 'gives a hash with default values' do
      expect(configured_permission_options)
        .to eq('Choose Access' => 'none',
               'Edit' => 'edit',
               'View/Download' => 'read')
    end

    context 'overridden as empty' do
      before do
        allow(Hyrax.config).to receive(:permission_options).and_return({})
      end

      it 'gives an empty hash' do
        expect(configured_permission_options).to eq({})
      end
    end

    context 'overridden with values' do
      let(:values) do
        { 'View/Download' => 'read', 'moomin' => 'edit' }
      end

      before do
        allow(Hyrax.config).to receive(:permission_options).and_return(values)
      end

      it 'gives i18nized hash' do
        expect { I18n.locale = :de }
          .to change { configured_permission_options }
          .from('Edit' => 'edit', 'View/Download' => 'read')
      end
    end
  end
end
