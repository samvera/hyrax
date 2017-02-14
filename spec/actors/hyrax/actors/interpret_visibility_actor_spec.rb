require 'spec_helper'
describe Hyrax::Actors::InterpretVisibilityActor do
  let(:user) { create(:user) }
  let(:curation_concern) { GenericWork.new }
  let(:attributes) { { admin_set_id: admin_set.id } }
  let(:admin_set) { create(:admin_set) }
  let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id) }

  subject do
    Hyrax::Actors::ActorStack.new(curation_concern,
                                  ::Ability.new(user),
                                  [described_class,
                                   Hyrax::Actors::GenericWorkActor])
  end
  let(:one_year_from_today) { Time.zone.today + 1.year }
  let(:two_years_from_today) { Time.zone.today + 2.years }
  let(:date) { Time.zone.today + 2 }

  describe 'the next actor' do
    let(:root_actor) { double }
    before do
      allow(Hyrax::Actors::RootActor).to receive(:new).and_return(root_actor)
      allow(curation_concern).to receive(:save).and_return(true)
    end

    context 'when visibility is set to open' do
      let(:attributes) do
        { visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
          visibility_during_embargo: 'restricted',
          visibility_after_embargo: 'open',
          embargo_release_date: date.to_s }
      end

      it 'does not receive the embargo attributes' do
        expect(root_actor).to receive(:create).with(visibility: 'open')
        subject.create(attributes)
      end
    end

    context 'when visibility is set to embargo' do
      let(:attributes) do
        { visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
          visibility_during_embargo: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE,
          visibility_after_embargo: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
          embargo_release_date: date.to_s }
      end

      it 'does not receive the visibility attribute' do
        expect(root_actor).to receive(:create).with(hash_excluding(:visibility))
        subject.create(attributes)
      end

      context 'when embargo_release_date is not set' do
        let(:attributes) { { visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO } }
        it 'does not clear the visibility attributes' do
          expect(subject.create(attributes)).to be false
          expect(attributes).to eq(visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO)
        end
      end
    end

    context 'when visibility is set to lease' do
      let(:attributes) do
        { visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE,
          visibility_during_lease: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE,
          visibility_after_lease: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
          lease_expiration_date: date.to_s }
      end

      it 'removes lease attributes' do
        expect(root_actor).to receive(:create).with(hash_excluding(:visibility))
        subject.create(attributes)
      end

      context 'when lease_expiration_date is not set' do
        let(:attributes) { { visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE } }
        it 'sets error on curation_concern and return false' do
          expect(subject.create(attributes)).to be false
          expect(attributes).to eq(visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE)
        end
      end
    end
  end

  describe 'create' do
    context 'with embargo' do
      let(:attributes) do
        { title: ['New embargo'], visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
          visibility_during_embargo: 'authenticated', embargo_release_date: date.to_s,
          visibility_after_embargo: 'open', visibility_during_lease: 'open',
          lease_expiration_date: '2014-06-12', visibility_after_lease: 'restricted',
          rights: ['http://creativecommons.org/licenses/by/3.0/us/'] }
      end

      context 'with a valid embargo date (and no template requirements)' do
        let(:date) { Time.zone.today + 2 }
        it 'interprets and apply embargo and lease visibility settings' do
          subject.create(attributes)
          expect(curation_concern.visibility_during_embargo).to eq 'authenticated'
          expect(curation_concern.visibility_after_embargo).to eq 'open'
          expect(curation_concern.visibility).to eq 'authenticated'
        end
      end

      context "embargo with invalid embargo date" do
        let(:attributes) do
          { title: ['New embargo'],
            admin_set_id: admin_set.id,
            visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
            embargo_release_date: 'ffff' }
        end

        it "returns false and logs error on date field" do
          permission_template # Ensuring permission_template is loaded
          expect(subject.create(attributes)).to be false
          expect(subject.curation_concern.errors[:embargo_release_date].first).to eq 'Must be a future date.'
        end
      end

      context 'when embargo_release_date is in the past' do
        let(:date) { Time.zone.today - 2 }
        it 'sets error on curation_concern and return false' do
          expect(subject.create(attributes)).to be false
          expect(subject.curation_concern.errors[:embargo_release_date].first).to eq 'Must be a future date.'
        end
      end

      context "embargo with missing embargo date" do
        let(:attributes) { { title: ['New embargo'], admin_set_id: admin_set.id, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO } }
        it "returns false and logs error on visibility field" do
          permission_template # Ensuring permission_template is loaded
          expect(subject.create(attributes)).to be false
          expect(subject.curation_concern.errors[:visibility].first).to eq 'When setting visibility to "embargo" you must also specify embargo release date.'
        end
      end

      context "embargo with date = one year from today, and required embargo of 6 months or less" do
        let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_6_MONTHS) }
        let(:attributes) do
          { title: ['New embargo'],
            admin_set_id: admin_set.id,
            visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
            embargo_release_date: one_year_from_today.to_s }
        end

        it "returns false and logs error on date field" do
          permission_template.reload
          expect(subject.create(attributes)).to be false
          expect(subject.curation_concern.errors[:embargo_release_date].first).to eq 'Release date specified does not match permission template release requirements for selected AdminSet.'
        end
      end

      context "embargo with date = one year from today, and required embargo of 1 year or less" do
        let(:permission_template) do
          create(:permission_template,
                 admin_set_id: admin_set.id,
                 release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR)
        end
        let(:attributes) do
          { title: ['New embargo'],
            admin_set_id: admin_set.id,
            visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
            embargo_release_date: one_year_from_today.to_s }
        end

        it "returns true" do
          permission_template.reload
          expect(subject.create(attributes)).to be true
        end
      end

      context "embargo with date that doesn't match a required, fixed date" do
        let(:permission_template) do
          create(:permission_template,
                 admin_set_id: admin_set.id,
                 release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED,
                 release_date: one_year_from_today.to_s)
        end
        let(:attributes) do
          { title: ['New embargo'],
            admin_set_id: admin_set.id,
            visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
            embargo_release_date: two_years_from_today.to_s }
        end

        it "returns false and logs error on date field" do
          permission_template.reload
          expect(subject.create(attributes)).to be false
          expect(subject.curation_concern.errors[:embargo_release_date].first).to eq 'Release date specified does not match permission template release requirements for selected AdminSet.'
        end
      end

      context "embargo with date matching the required, fixed date" do
        let(:permission_template) do
          create(:permission_template,
                 admin_set_id: admin_set.id,
                 release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED,
                 release_date: two_years_from_today.to_s)
        end
        let(:attributes) do
          { title: ['New embargo'],
            admin_set_id: admin_set.id,
            visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
            embargo_release_date: two_years_from_today.to_s }
        end

        it "returns true" do
          permission_template.reload
          expect(subject.create(attributes)).to be true
        end
      end

      context "embargo with valid embargo date and invalid post-embargo visibility" do
        let(:permission_template) do
          create(:permission_template,
                 admin_set_id: admin_set.id,
                 release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR,
                 visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
        end
        let(:attributes) do
          { title: ['New embargo'],
            admin_set_id: admin_set.id,
            visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
            embargo_release_date: one_year_from_today.to_s,
            visibility_after_embargo: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
        end

        it "returns false and logs error on visibility field" do
          permission_template.reload
          expect(subject.create(attributes)).to be false
          expect(subject.curation_concern.errors[:visibility_after_embargo].first).to eq 'Visibility after embargo does not match permission template visibility requirements for selected AdminSet.'
        end
      end

      context "embargo with valid embargo date and valid post-embargo visibility" do
        let(:permission_template) do
          create(:permission_template,
                 admin_set_id: admin_set.id,
                 release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR,
                 visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
        end
        let(:attributes) do
          { title: ['New embargo'],
            admin_set_id: admin_set.id,
            visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
            embargo_release_date: one_year_from_today.to_s,
            visibility_after_embargo: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
        end

        it "returns true" do
          permission_template.reload
          expect(subject.create(attributes)).to be true
        end
      end

      context "embargo with public visibility and public visibility required (no specified release_period in template)" do
        let(:permission_template) do
          create(:permission_template,
                 admin_set_id: admin_set.id,
                 visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
        end
        let(:attributes) do
          { title: ['New embargo'],
            admin_set_id: admin_set.id,
            visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
            embargo_release_date: one_year_from_today.to_s,
            visibility_after_embargo: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
        end

        it "returns true" do
          permission_template.reload
          expect(subject.create(attributes)).to be true
        end
      end

      context "embargo with public visibility and authenticated visibility required (no specified release_period in template)" do
        let(:permission_template) do
          create(:permission_template,
                 admin_set_id: admin_set.id,
                 visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
        end
        let(:attributes) do
          { title: ['New embargo'],
            admin_set_id: admin_set.id,
            visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
            embargo_release_date: one_year_from_today.to_s,
            visibility_after_embargo: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
        end

        it "returns false and logs error on visibility field" do
          permission_template.reload
          expect(subject.create(attributes)).to be false
          expect(subject.curation_concern.errors[:visibility_after_embargo].first).to eq 'Visibility after embargo does not match permission template visibility requirements for selected AdminSet.'
        end
      end

      context "embargo when no release delays are allowed" do
        let(:permission_template) do
          create(:permission_template,
                 admin_set_id: admin_set.id,
                 release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY)
        end
        let(:attributes) do
          { title: ['New embargo'],
            admin_set_id: admin_set.id,
            visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
            embargo_release_date: one_year_from_today.to_s }
        end

        it "returns false and logs error on visiblity field" do
          permission_template.reload
          expect(subject.create(attributes)).to be false
          expect(subject.curation_concern.errors[:visibility].first).to eq 'Visibility specified does not match permission template "no release delay" requirement for selected AdminSet.'
        end
      end

      context "no embargo/lease when no release delays are allowed" do
        let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY) }
        let(:attributes) { { title: ['New embargo'], admin_set_id: admin_set.id, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC } }

        it "returns true" do
          permission_template.reload
          expect(subject.create(attributes)).to be true
        end
      end

      context "visibility public (no embargo) when visibility required to be authenticated" do
        let(:permission_template) do
          create(:permission_template,
                 admin_set_id: admin_set.id,
                 release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY,
                 visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
        end
        let(:attributes) { { title: ['New embargo'], admin_set_id: admin_set.id, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC } }

        it "returns false and logs an error on visibility field" do
          permission_template.reload
          expect(subject.create(attributes)).to be false
          expect(subject.curation_concern.errors[:visibility].first).to eq 'Visibility specified does not match permission template visibility requirement for selected AdminSet.'
        end
      end

      context "visibility public (no embargo) and visibility required to be public" do
        let(:permission_template) do
          create(:permission_template,
                 admin_set_id: admin_set.id,
                 release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY,
                 visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
        end
        let(:attributes) { { title: ['New embargo'], admin_set_id: admin_set.id, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC } }

        it "returns true" do
          permission_template.reload
          expect(subject.create(attributes)).to be true
        end
      end

      context "lease specified with any release/visibility requirements" do
        let(:permission_template) do
          create(:permission_template,
                 admin_set_id: admin_set.id,
                 release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR,
                 visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
        end
        let(:attributes) do
          { title: ['New embargo'],
            admin_set_id: admin_set.id,
            visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE,
            lease_expiration_date: one_year_from_today.to_s,
            visibility_after_lease: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
        end

        it "returns false and logs an error on visibility field" do
          permission_template.reload
          expect(subject.create(attributes)).to be false
          expect(subject.curation_concern.errors[:visibility].first).to eq 'Lease option is not allowed by permission template for selected AdminSet.'
        end
      end

      context "lease specified with NO release/visibility requirements" do
        let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id) }
        let(:attributes) do
          { title: ['New embargo'],
            admin_set_id: admin_set.id,
            visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE,
            lease_expiration_date: one_year_from_today.to_s,
            visibility_after_lease: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
        end

        it "returns true" do
          permission_template.reload
          expect(subject.create(attributes)).to be true
        end
      end
    end

    context 'with lease' do
      let(:attributes) do
        { title: ['New embargo'], visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE,
          visibility_during_embargo: 'authenticated', embargo_release_date: '2099-05-12',
          visibility_after_embargo: 'open', visibility_during_lease: 'open',
          lease_expiration_date: date.to_s, visibility_after_lease: 'restricted',
          rights: ['http://creativecommons.org/licenses/by/3.0/us/'] }
      end

      context 'with a valid lease date' do
        let(:date) { Time.zone.today + 2 }
        it 'interprets and apply embargo and lease visibility settings' do
          subject.create(attributes)
          expect(curation_concern.embargo_release_date).to be_nil
          expect(curation_concern.visibility_during_lease).to eq 'open'
          expect(curation_concern.visibility_after_lease).to eq 'restricted'
          expect(curation_concern.visibility).to eq 'open'
        end
      end

      context 'when lease_expiration_date is in the past' do
        let(:date) { Time.zone.today - 2 }
        it 'sets error on curation_concern and return false' do
          expect(subject.create(attributes)).to be false
          expect(subject.curation_concern.errors[:lease_expiration_date].first).to eq 'Must be a future date'
        end
      end
    end
  end
end
