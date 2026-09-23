# frozen_string_literal: true

RSpec.describe Hyrax::ProfileViolation do
  subject(:violation) { described_class.new(severity: severity, message: 'something is wrong') }

  describe '#error?' do
    context 'when the severity is :error' do
      let(:severity) { :error }

      it { is_expected.to be_error }
      it { is_expected.not_to be_warning }
    end

    context 'when the severity is :warning' do
      let(:severity) { :warning }

      it { is_expected.to be_warning }
      it { is_expected.not_to be_error }
    end
  end
end
