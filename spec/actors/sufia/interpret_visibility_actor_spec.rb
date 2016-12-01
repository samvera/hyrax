require 'spec_helper'

RSpec.describe Sufia::InterpretVisibilityActor do
  let(:create_actor) do
    double('create actor', create: true,
                           curation_concern: work,
                           user: depositor)
  end
  let(:depositor) { create(:user) }
  let(:work) { build(:generic_work) }
  let(:admin_set) { create(:admin_set) }
  let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id) }
  let(:attributes) { { admin_set_id: admin_set.id } }
  subject do
    CurationConcerns::Actors::ActorStack.new(work, depositor, [described_class])
  end
  let(:one_year_from_today) { Time.zone.today + 1.year }
  let(:two_years_from_today) { Time.zone.today + 2.years }

  describe "create" do
    context "embargo with missing embargo date" do
      let(:attributes) { { admin_set_id: admin_set.id, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO } }

      it "returns false and logs error on visibility field" do
        expect(subject.create(attributes)).to be false
        expect(subject.curation_concern.errors[:visibility].first).to eq 'When setting visibility to "embargo" you must also specify embargo release date.'
      end
    end

    context "embargo with invalid embargo date" do
      let(:attributes) { { admin_set_id: admin_set.id, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO, embargo_release_date: 'ffff' } }

      it "returns false and logs error on date field" do
        expect(subject.create(attributes)).to be false
        expect(subject.curation_concern.errors[:embargo_release_date].first).to eq 'Must be a future date.'
      end
    end

    context "embargo with past embargo date" do
      let(:attributes) { { admin_set_id: admin_set.id, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO, embargo_release_date: '1999-12-31' } }

      it "returns false and logs error on date field" do
        expect(subject.create(attributes)).to be false
        expect(subject.curation_concern.errors[:embargo_release_date].first).to eq 'Must be a future date.'
      end
    end

    context "embargo with future embargo date (and no template requirements)" do
      let(:attributes) { { admin_set_id: admin_set.id, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO, embargo_release_date: one_year_from_today.to_s } }

      it "returns true" do
        expect(subject.create(attributes)).to be true
      end
    end

    context "embargo with date = one year from today, and required embargo of 6 months or less" do
      let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id, release_period: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_6_MONTHS) }
      let(:attributes) { { admin_set_id: admin_set.id, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO, embargo_release_date: one_year_from_today.to_s } }

      it "returns false and logs error on date field" do
        permission_template.reload
        expect(subject.create(attributes)).to be false
        expect(subject.curation_concern.errors[:embargo_release_date].first).to eq 'Release date specified does not match permission template release requirements for selected AdminSet.'
      end
    end

    context "embargo with date = one year from today, and required embargo of 1 year or less" do
      let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id, release_period: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR) }
      let(:attributes) { { admin_set_id: admin_set.id, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO, embargo_release_date: one_year_from_today.to_s } }

      it "returns true" do
        permission_template.reload
        expect(subject.create(attributes)).to be true
      end
    end

    context "embargo with date that doesn't match a required, fixed date" do
      let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id, release_period: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED, release_date: one_year_from_today.to_s) }
      let(:attributes) { { admin_set_id: admin_set.id, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO, embargo_release_date: two_years_from_today.to_s } }

      it "returns false and logs error on date field" do
        permission_template.reload
        expect(subject.create(attributes)).to be false
        expect(subject.curation_concern.errors[:embargo_release_date].first).to eq 'Release date specified does not match permission template release requirements for selected AdminSet.'
      end
    end

    context "embargo with date matching the required, fixed date" do
      let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id, release_period: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED, release_date: two_years_from_today.to_s) }
      let(:attributes) { { admin_set_id: admin_set.id, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO, embargo_release_date: two_years_from_today.to_s } }

      it "returns true" do
        permission_template.reload
        expect(subject.create(attributes)).to be true
      end
    end

    context "embargo with valid embargo date and invalid post-embargo visibility" do
      let(:permission_template) do
        create(:permission_template,
               admin_set_id: admin_set.id,
               release_period: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR,
               visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
      end
      let(:attributes) do
        { admin_set_id: admin_set.id,
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
               release_period: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR,
               visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
      end
      let(:attributes) do
        { admin_set_id: admin_set.id,
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
        { admin_set_id: admin_set.id,
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
        { admin_set_id: admin_set.id,
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
      let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id, release_period: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY) }
      let(:attributes) { { admin_set_id: admin_set.id, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO, embargo_release_date: one_year_from_today.to_s } }

      it "returns false and logs error on visiblity field" do
        permission_template.reload
        expect(subject.create(attributes)).to be false
        expect(subject.curation_concern.errors[:visibility].first).to eq 'Visibility specified does not match permission template "no release delay" requirement for selected AdminSet.'
      end
    end

    context "no embargo/lease when no release delays are allowed" do
      let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id, release_period: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY) }
      let(:attributes) { { admin_set_id: admin_set.id, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC } }

      it "returns true" do
        permission_template.reload
        expect(subject.create(attributes)).to be true
      end
    end

    context "visibility public (no embargo) when visibility required to be authenticated" do
      let(:permission_template) do
        create(:permission_template,
               admin_set_id: admin_set.id,
               release_period: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY,
               visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
      end
      let(:attributes) { { admin_set_id: admin_set.id, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC } }

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
               release_period: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY,
               visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
      end
      let(:attributes) { { admin_set_id: admin_set.id, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC } }

      it "returns true" do
        permission_template.reload
        expect(subject.create(attributes)).to be true
      end
    end

    context "lease specified with any release/visibility requirements" do
      let(:permission_template) do
        create(:permission_template,
               admin_set_id: admin_set.id,
               release_period: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR,
               visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
      end
      let(:attributes) do
        { admin_set_id: admin_set.id,
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
        { admin_set_id: admin_set.id,
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
end
