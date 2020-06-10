# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::Steps::ApplyVisibility do
  subject(:step) { described_class.new }
  let(:work)     { build(:generic_work) }

  describe '#call' do
    it 'is a success' do
      expect(step.call(work)).to be_success
    end

    context 'without a visibility' do
      it 'retains the existing visibility' do
        expect { step.call(work) }
          .not_to change { work.visibility }
      end
    end

    context 'when setting visibility explictly' do
      let(:visibility) { 'open' }

      it 'applies the custom visibility embargo' do
        expect { step.call(work, visibility: visibility) }
          .to change { work.visibility }
          .to visibility
      end
    end

    context 'when setting a lease' do
      let(:visibility) { 'lease' }
      let(:end_date)   { (Time.zone.now + 2).to_s }
      let(:after)      { 'restricted' }
      let(:during)     { 'open' }
      let(:opts) do
        { visibility: visibility,
          release_date: end_date,
          after: after,
          during: during }
      end

      it 'interprets and applies the lease' do
        expect { step.call(work, **opts) }
          .to change { work.lease }
          .to be_a_lease_matching(release_date: end_date, during: during, after: after)
      end

      context 'with missing end date' do
        it 'is a failure' do
          expect(step.call(work, visibility: visibility)).to be_failure
        end
      end
    end

    context 'when setting an embargo' do
      let(:visibility) { 'embargo' }
      let(:end_date)   { (Time.zone.now + 2).to_s }
      let(:after)      { 'open' }
      let(:during)     { 'restricted' }

      let(:opts) do
        { visibility: visibility,
          release_date: end_date,
          after: after,
          during: during }
      end

      it 'interprets and applies the embargo' do
        expect { step.call(work, **opts) }
          .to change { work.embargo }
          .to be_an_embargo_matching(release_date: end_date, during: during, after: after)
      end

      context 'with missing end date' do
        it 'is a failure' do
          expect(step.call(work, visibility: visibility)).to be_failure
        end
      end
    end
  end
end
