# frozen_string_literal: true

# NOTE: Leases and Embargoes have separate managers for Valkyrie objects.
RSpec.describe Hyrax::VisibilityIntentionApplicator, :active_fedora do
  subject(:applicator) { described_class.new(intention: intention) }
  let(:work)           { build(:work) }

  let(:intention) do
    instance_double(Hyrax::VisibilityIntention,
                    'wants_embargo?': false,
                    'wants_lease?': false,
                    visibility: Hyrax::VisibilityIntention::PUBLIC)
  end

  describe '#apply' do
    it 'initializes with intention' do
      expect(described_class.apply(intention))
        .to have_attributes(intention: intention)
    end
  end

  describe '#apply_to' do
    it 'applies simple visibility' do
      expect { applicator.apply_to(model: work) }
        .to change { work.visibility }
        .to Hyrax::VisibilityIntention::PUBLIC
    end

    context 'when applying an embargo' do
      let(:after)    { Hyrax::VisibilityIntention::PUBLIC }
      let(:params)   { [end_date, during, after] }
      let(:end_date) { (Time.zone.now + 2).to_s }
      let(:during)   { Hyrax::VisibilityIntention::PRIVATE }

      let(:intention) do
        instance_double(Hyrax::VisibilityIntention,
                        'wants_embargo?': true,
                        'wants_lease?': false,
                        'valid_embargo?': true,
                        embargo_params: params)
      end

      it 'applies an embargo' do
        expect { applicator.apply_to(model: work) }
          .to change { work.embargo }
          .to be_an_embargo_matching(release_date: end_date, during: during, after: after)
      end
    end

    context 'when applying a lease' do
      let(:after)    { Hyrax::VisibilityIntention::PUBLIC }
      let(:during)   { Hyrax::VisibilityIntention::PRIVATE }
      let(:params)   { [end_date, during, after] }
      let(:end_date) { (Time.zone.now + 2).to_s }

      let(:intention) do
        instance_double(Hyrax::VisibilityIntention,
                        'wants_embargo?': false,
                        'wants_lease?': true,
                        'valid_lease?': true,
                        lease_params: params)
      end

      it 'applies an lease' do
        expect { applicator.apply_to(model: work) }
          .to change { work.lease }
          .to be_a_lease_matching(release_date: end_date, during: during, after: after)
      end
    end
  end
end
