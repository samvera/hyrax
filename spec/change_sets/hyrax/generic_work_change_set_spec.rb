RSpec.describe GenericWorkChangeSet do
  subject(:change_set) { described_class.new(work, attributes) }

  let(:admin_set) { create_for_repository(:admin_set) }
  let(:attributes) { {} }
  let(:work) { GenericWork.new }

  describe "validations" do
    let(:date) { Time.zone.today + 2 }

    it "is valid by default" do
      expect(change_set).to be_valid
    end

    context 'when visibility is set to public' do
      let(:attributes) do
        { visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
          visibility_during_embargo: 'restricted',
          visibility_after_embargo: 'open',
          embargo_release_date: date.to_s }
      end

      it 'is valid' do
        expect(change_set).to be_valid
        # TODO: and creates neither embargo no lease?
      end

      context "and visibility required to be authenticated" do
        before do
          create(:permission_template,
                 admin_set_id: admin_set.id,
                 release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY,
                 visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
        end
        let(:attributes) { { title: ['New embargo'], admin_set_id: admin_set.id.to_s, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC } }

        it "is invalid and logs an error on visibility field" do
          expect(change_set).not_to be_valid
          expect(change_set.errors[:visibility].first).to eq 'Visibility specified does not match permission template visibility requirement for selected AdminSet.'
        end
      end

      context "and visibility required to be public" do
        before do
          create(:permission_template,
                 admin_set_id: admin_set.id,
                 release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY,
                 visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
        end
        let(:attributes) { { title: ['New embargo'], admin_set_id: admin_set.id.to_s, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC } }

        it "is valid" do
          expect(change_set).to be_valid
        end
      end
    end

    context 'when visibility is set to embargo' do
      let(:one_year_from_today) { Time.zone.today + 1.year }
      let(:two_years_from_today) { Time.zone.today + 2.years }
      let(:attributes) do
        { visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
          visibility_during_embargo: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE,
          visibility_after_embargo: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
          embargo_release_date: date.to_s }
      end

      it 'is valid' do
        expect(change_set).to be_valid
        # TODO: and creates embargo?
      end

      context 'and embargo_release_date is not set' do
        let(:attributes) { { visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO } }

        it 'is not valid' do
          expect(change_set).not_to be_valid
          expect(change_set.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO
          expect(change_set.errors[:visibility].first).to eq 'When setting visibility to "embargo" you must also specify embargo release date.'
        end
      end

      context "and embargo_release_date is invalid" do
        let(:attributes) do
          { title: ['New embargo'],
            visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
            embargo_release_date: 'ffff' }
        end

        it "is invalid and logs error on date field" do
          expect(change_set).not_to be_valid
          expect(change_set.errors[:embargo_release_date].first).to eq 'Must be a future date.'
        end
      end

      context 'and embargo_release_date is in the past' do
        let(:date) { Time.zone.today - 2 }

        it 'is invalid and sets an error' do
          expect(change_set).not_to be_valid
          expect(change_set.errors[:embargo_release_date].first).to eq 'Must be a future date.'
        end
      end

      context "and date = one year from today, and required embargo of 6 months or less" do
        before do
          create(:permission_template, admin_set_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_6_MONTHS)
        end
        let(:attributes) do
          { title: ['New embargo'],
            admin_set_id: admin_set.id.to_s,
            visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
            embargo_release_date: one_year_from_today.to_s }
        end

        it "is invalid and logs error on date field" do
          expect(change_set).not_to be_valid
          expect(change_set.errors[:embargo_release_date].first).to eq 'Release date specified does not match permission template release requirements for selected AdminSet.'
        end
      end

      context "embargo with date = one year from today, and required embargo of 1 year or less" do
        before do
          create(:permission_template,
                 admin_set_id: admin_set.id,
                 release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR)
        end
        let(:attributes) do
          { title: ['New embargo'],
            admin_set_id: admin_set.id.to_s,
            visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
            embargo_release_date: one_year_from_today.to_s }
        end

        it "is valid" do
          expect(change_set).to be_valid
        end
      end

      context "embargo with date that doesn't match a required, fixed date" do
        before do
          create(:permission_template,
                 admin_set_id: admin_set.id,
                 release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED,
                 release_date: one_year_from_today.to_s)
        end
        let(:attributes) do
          { title: ['New embargo'],
            admin_set_id: admin_set.id.to_s,
            visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
            embargo_release_date: two_years_from_today.to_s }
        end

        it "is invalid and logs error on date field" do
          expect(change_set).not_to be_valid
          expect(change_set.errors[:embargo_release_date].first).to eq 'Release date specified does not match permission template release requirements for selected AdminSet.'
        end
      end

      context "embargo with date matching the required, fixed date" do
        before do
          create(:permission_template,
                 admin_set_id: admin_set.id,
                 release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED,
                 release_date: two_years_from_today.to_s)
        end
        let(:attributes) do
          { title: ['New embargo'],
            admin_set_id: admin_set.id.to_s,
            visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
            embargo_release_date: two_years_from_today.to_s }
        end

        it "is valid" do
          expect(change_set).to be_valid
        end
      end

      context "embargo with valid embargo date and invalid post-embargo visibility" do
        before do
          create(:permission_template,
                 admin_set_id: admin_set.id,
                 release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR,
                 visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
        end
        let(:attributes) do
          { title: ['New embargo'],
            admin_set_id: admin_set.id.to_s,
            visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
            embargo_release_date: one_year_from_today.to_s,
            visibility_after_embargo: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
        end

        it "is invalid and logs error on visibility field" do
          expect(change_set).not_to be_valid
          expect(change_set.errors[:visibility_after_embargo].first).to eq 'Visibility after embargo does not match permission template visibility requirements for selected AdminSet.'
        end
      end

      context "with valid embargo date and valid post-embargo visibility" do
        before do
          create(:permission_template,
                 admin_set_id: admin_set.id,
                 release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR,
                 visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
        end
        let(:attributes) do
          { title: ['New embargo'],
            admin_set_id: admin_set.id.to_s,
            visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
            embargo_release_date: one_year_from_today.to_s,
            visibility_after_embargo: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
        end

        it "is valid" do
          expect(change_set).to be_valid
        end
      end

      context "embargo with public visibility and public visibility required (no specified release_period in template)" do
        before do
          create(:permission_template,
                 admin_set_id: admin_set.id,
                 visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
        end
        let(:attributes) do
          { title: ['New embargo'],
            admin_set_id: admin_set.id.to_s,
            visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
            embargo_release_date: one_year_from_today.to_s,
            visibility_after_embargo: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
        end

        it "is valid" do
          expect(change_set).to be_valid
        end
      end

      context "embargo with public visibility and authenticated visibility required (no specified release_period in template)" do
        before do
          create(:permission_template,
                 admin_set_id: admin_set.id,
                 visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
        end
        let(:attributes) do
          { title: ['New embargo'],
            admin_set_id: admin_set.id.to_s,
            visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
            embargo_release_date: one_year_from_today.to_s,
            visibility_after_embargo: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
        end

        it "is invalid and logs error on visibility field" do
          expect(change_set).not_to be_valid
          expect(change_set.errors[:visibility_after_embargo].first).to eq 'Visibility after embargo does not match permission template visibility requirements for selected AdminSet.'
        end
      end

      context "embargo when no release delays are allowed" do
        before do
          create(:permission_template,
                 admin_set_id: admin_set.id,
                 release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY)
        end
        let(:attributes) do
          { title: ['New embargo'],
            admin_set_id: admin_set.id.to_s,
            visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
            embargo_release_date: one_year_from_today.to_s }
        end

        it "is invalid and logs error on visiblity field" do
          expect(change_set).not_to be_valid
          expect(change_set.errors[:visibility].first).to eq 'Visibility specified does not match permission template "no release delay" requirement for selected AdminSet.'
        end
      end

      context "no embargo/lease when no release delays are allowed" do
        before do
          create(:permission_template, admin_set_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY)
        end
        let(:attributes) { { title: ['New embargo'], admin_set_id: admin_set.id.to_s, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC } }

        it "is valid" do
          expect(change_set).to be_valid
        end
      end
    end

    context 'when visibility is set to lease' do
      let(:one_year_from_today) { Time.zone.today + 1.year }
      let(:attributes) do
        { visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE,
          visibility_during_lease: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE,
          visibility_after_lease: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
          lease_expiration_date: date.to_s }
      end

      it 'is valid' do
        expect(change_set).to be_valid
        # TODO: and creates lease?
      end

      context 'and lease_expiration_date is not set' do
        let(:attributes) { { visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE } }

        it 'sets error on curation_concern and return false' do
          expect(change_set).not_to be_valid
          expect(change_set.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE
        end
      end

      context 'and lease_expiration_date is in the past' do
        let(:date) { Time.zone.today - 2 }

        it 'is invalid and sets an error' do
          expect(change_set).not_to be_valid
          expect(change_set.errors[:lease_expiration_date].first).to eq 'Must be a future date.'
        end
      end

      context "with NO release/visibility requirements" do
        before { create(:permission_template, admin_set_id: admin_set.id) }
        let(:attributes) do
          { title: ['New embargo'],
            admin_set_id: admin_set.id.to_s,
            visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE,
            lease_expiration_date: one_year_from_today.to_s,
            visibility_after_lease: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
        end

        it "is valid" do
          expect(change_set).to be_valid
        end
      end

      context "and any release/visibility requirements" do
        before do
          create(:permission_template,
                 admin_set_id: admin_set.id,
                 release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR,
                 visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
        end
        let(:attributes) do
          { title: ['New embargo'],
            admin_set_id: admin_set.id.to_s,
            visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE,
            lease_expiration_date: one_year_from_today.to_s,
            visibility_after_lease: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
        end

        it "is invalid and logs an error on visibility field" do
          expect(change_set).not_to be_valid
          expect(change_set.errors[:visibility].first).to eq 'Lease option is not allowed by permission template for selected AdminSet.'
        end
      end
    end

    context "validates linked_data_attributes" do
      it "validates with a valid uri " do
        work.based_near = ['http://sws.geonames.org/3413829']
        expect(change_set).to be_valid
      end
      it "does not validate with an invalid uri" do
        work.based_near = [RDF::URI('3413829')]
        expect(change_set).not_to be_valid
      end
    end
  end

  describe "#fields" do
    subject { change_set.fields.keys }

    # rubocop:disable RSpec/ExampleLength
    it do
      is_expected.to include("created_at", "updated_at", "depositor", "title",
                             "date_uploaded", "date_modified", "admin_set_id",
                             "state", "proxy_depositor", "on_behalf_of",
                             "arkivo_checksum", "member_of_collection_ids",
                             "member_ids", "thumbnail_id", "representative_id",
                             "label", "relative_path", "resource_type", "creator",
                             "contributor", "description", "keyword", "license",
                             "rights_statement",
                             "publisher", "date_created", "subject", "language",
                             "identifier", "related_url", "source", "based_near")
    end
    # rubocop:enable RSpec/ExampleLength
  end

  describe "#primary_terms" do
    subject { change_set.primary_terms }

    it { is_expected.to eq [:title, :creator, :keyword, :rights_statement] }
  end

  describe "#secondary_terms" do
    subject { change_set.secondary_terms }

    it do
      is_expected.not_to include(:title, :creator, :keyword,
                                 :visibilty, :visibility_during_embargo,
                                 :embargo_release_date, :visibility_after_embargo,
                                 :visibility_during_lease, :lease_expiration_date,
                                 :visibility_after_lease, :collection_ids)
    end
  end

  describe "#permissions" do
    let(:work) do
      GenericWork.new(edit_users: ['bob'],
                      read_users: ['lynda'],
                      edit_groups: ['librarians'],
                      read_groups: ['patrons'])
    end
    let(:service) { instance_double(Hyrax::AdminSetService, search_results: []) }
    let(:search_context) { instance_double(Hyrax::ResourceController::SearchContext) }
    let(:attributes) { { search_context: search_context } }

    before do
      allow(Hyrax::AdminSetService).to receive(:new).with(search_context).and_return(service)
      change_set.prepopulate!
    end

    it "has them" do
      expect(change_set.permissions[0].agent_name).to eq 'bob'
      expect(change_set.permissions[0].type).to eq 'person'
      expect(change_set.permissions[0].access).to eq 'edit'
    end
  end
end
