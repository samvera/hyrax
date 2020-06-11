# frozen_string_literal: true
RSpec.describe Hyrax::BatchCreateOperation do
  subject { create(:batch_create_operation) }

  describe 'callbacks' do
    before do
      allow(Hyrax.config.callback).to receive(:set?).with(callback).and_return(callback_set)
    end

    describe '#batch_success_message' do
      let(:callback) { :after_batch_create_success }
      let(:callback_set) { false }

      it 'can be called' do
        expect(subject).to respond_to(:batch_success_message)
      end

      context 'when callback not set' do
        it 'returns nil' do
          expect(Hyrax.config.callback).not_to receive(:run)
          expect(subject.batch_success_message).to be_nil
        end
      end

      context 'when callback is set' do
        let(:callback_set) { true }

        it 'runs the callback' do
          expect(Hyrax.config.callback).to receive(:run).once
          subject.batch_success_message
        end
      end
    end

    describe '#batch_failure_message' do
      let(:callback) { :after_batch_create_failure }
      let(:callback_set) { false }

      it 'can be called' do
        expect(subject).to respond_to(:batch_failure_message)
      end

      context 'when callback not set' do
        it 'returns nil' do
          expect(Hyrax.config.callback).not_to receive(:run)
          expect(subject.batch_failure_message).to be_nil
        end
      end

      context 'when callback is set' do
        let(:callback_set) { true }

        it 'runs the callback' do
          expect(Hyrax.config.callback).to receive(:run).once
          subject.batch_failure_message
        end
      end
    end
  end
end
