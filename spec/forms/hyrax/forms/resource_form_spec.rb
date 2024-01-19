# frozen_string_literal: true

RSpec.describe Hyrax::Forms::ResourceForm do
  subject(:form) { described_class.for(work) }
  let(:work)     { Hyrax::Work.new }

  let(:default_admin_set) { instance_double(Hyrax::AdministrativeSet, title: "DEFAULT_ADMINSET", id: "DEFAULT_ADMINSET_ID") }
  before { allow(Hyrax::AdminSetCreateService).to receive(:find_or_create_default_admin_set).and_return(default_admin_set) }

  describe '.required_fields=' do
    subject(:form) { form_class.new(work) }

    let(:form_class) do
      Class.new(Hyrax::Forms::ResourceForm(work.class)) do
        property :depositor
      end
    end

    it 'lists required fields' do
      expect(form_class.required_fields).to contain_exactly :title
    end

    it 'can add required fields' do
      expect { form_class.required_fields += [:depositor] }
        .to change { form.required?(:depositor) && form.required?(:title) }
        .to true
    end
  end

  describe '.model_class' do
    it 'is the class of the configured work' do
      expect(Hyrax::Forms::ResourceForm(work.class).model_class)
        .to eq work.class
    end
  end

  describe '#[]' do
    it 'supports access to work attributes' do
      expect(form[:title]).to eq work.title
    end

    it 'gives nil for unsupported attributes' do
      expect(form[:not_a_real_attribute]).to be_nil
    end
  end

  describe '#[]=' do
    it 'supports setting work attributes' do
      new_title = 'comet in moominland'

      expect { form[:title] = new_title }
        .to change { form[:title] }
        .to new_title
    end
  end

  describe '#admin_set_id' do
    it 'is nil' do
      expect(form.admin_set_id).to be_nil
    end

    it 'prepopulates to the default admin set' do
      expect { form.prepopulate! }
        .to change { form.admin_set_id }
        .to Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id.to_s
    end
  end

  describe '#agreement_accepted' do
    it { is_expected.to have_attributes(agreement_accepted: false) }

    it 'remains false when prepopulated' do
      expect { form.prepopulate! }
        .not_to change { form.agreement_accepted }
        .from false
    end

    context 'when the work already exists' do
      let(:work) { FactoryBot.valkyrie_create(:hyrax_work) }

      it 'prepopulates to true' do
        expect { form.prepopulate! }
          .to change { form.agreement_accepted }
          .to true
      end
    end
  end

  describe '#based_near' do
    subject(:form) { form_class.new(work) }

    let(:work) { build(:monograph) }
    let(:geonames_uri) { "https://sws.geonames.org/4254679/" }

    let(:form_class) do
      Class.new(Hyrax::Forms::ResourceForm(work.class)) do
        include Hyrax::FormFields(:basic_metadata)
      end
    end

    it 'runs the based_near prepopulator' do
      work.based_near = [geonames_uri]
      form.prepopulate!
      expect(form.based_near)
        .to contain_exactly(an_instance_of(Hyrax::ControlledVocabularies::Location))
    end

    it 'runs the based_near populator' do
      form.validate(based_near_attributes: { "0" => { "hidden_label" => geonames_uri,
                                                      "id" => geonames_uri,
                                                      "_destroy" => "" } })
      expect(form.based_near)
        .to contain_exactly(geonames_uri)
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

    context 'with a work under embargo' do
      let(:work) { FactoryBot.build(:hyrax_work, :under_embargo) }

      it 'defaults to the embargo date' do
        expect { form.prepopulate! }
          .to change { form.embargo_release_date }
          .to(work.embargo.embargo_release_date)
      end
    end
  end

  describe '#in_works_ids' do
    context 'without membership' do
      it 'is an empty array' do
        form.prepopulate!

        expect(form.in_works_ids).to eq []
      end
    end

    context 'as a member of works' do
      let(:work)   { Hyrax.query_service.find_by(id: parent.member_ids.first) }
      let(:parent) { FactoryBot.valkyrie_create(:hyrax_work, :with_member_works) }

      it 'lists the parent works' do
        form.prepopulate!

        expect(form.in_works_ids).to contain_exactly(parent.id)
      end
    end

    context 'as a member of works and collections' do
      let(:work)   { FactoryBot.valkyrie_create(:hyrax_work, :as_collection_member) }
      let(:parent) { FactoryBot.valkyrie_create(:hyrax_work, :with_member_works, members: [work]) }

      before { parent } # parent must be saved

      it 'lists the parent works' do
        form.prepopulate!

        expect(form.in_works_ids).to contain_exactly(parent.id)
      end
    end

    context 'as a member of collections' do
      let(:work) { FactoryBot.valkyrie_create(:hyrax_work, :as_member_of_multiple_collections) }

      it 'is empty' do
        form.prepopulate!

        expect(form.in_works_ids.to_a).to eq []
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

    context 'with a work under embargo' do
      let(:work) { FactoryBot.build(:hyrax_work, :under_lease) }

      it 'defaults to the embargo date' do
        expect { form.prepopulate! }
          .to change { form.lease_expiration_date }
          .to(work.lease.lease_expiration_date)
      end
    end
  end

  describe '#member_ids' do
    it 'for a new object has empty membership' do
      expect(form.member_ids).to be_empty
    end

    it 'casts to an array' do
      expect { form.validate(member_ids: '123') }
        .to change { form.member_ids }
        .to contain_exactly('123')
    end

    context 'when the object has members' do
      let(:work) { FactoryBot.build(:monograph, :with_member_works) }

      it 'gives member work ids' do
        expect(form.member_ids).to contain_exactly(*work.member_ids.map(&:id))
      end
    end
  end

  describe '#member_of_collection_ids' do
    it 'for a new object has empty membership' do
      expect(form.member_of_collection_ids).to be_empty
    end

    context 'when collection membership is updated' do
      context 'from none to one' do
        let(:work) { FactoryBot.valkyrie_create(:hyrax_work, title: ['comet in moominland']) }
        let(:member_of_collections_attributes) do
          { "0" => { "id" => "123", "_destroy" => "false" } }
        end

        it 'is populated from member_of_collections_attributes' do
          form.validate(member_of_collections_attributes: member_of_collections_attributes)

          expect { form.sync }
            .to change { work.member_of_collection_ids }
            .to contain_exactly('123')
        end
      end

      context 'from 3 down to 2' do
        let(:work) do
          FactoryBot.valkyrie_create(:hyrax_work,
                                     member_of_collection_ids: before_collection_ids,
                                     title: ['comet in moominland'])
        end

        let(:col1) { FactoryBot.valkyrie_create(:hyrax_collection) }
        let(:col2) { FactoryBot.valkyrie_create(:hyrax_collection) }
        let(:col3) { FactoryBot.valkyrie_create(:hyrax_collection) }
        let(:before_collection_ids) { [col1.id, col2.id, col3.id] }
        let(:after_collection_ids) { [col1.id.to_s, col2.id.to_s] }

        let(:member_of_collections_attributes) do
          { "0" => { "id" => col1.id.to_s, "_destroy" => "false" },
            "1" => { "id" => col2.id.to_s, "_destroy" => "false" },
            "2" => { "id" => col3.id.to_s, "_destroy" => "true" } }
        end

        it 'is populated from member_of_collections_attributes' do
          form.validate(member_of_collections_attributes: member_of_collections_attributes)

          expect { form.sync }
            .to change { work.member_of_collection_ids }
            .to contain_exactly(*after_collection_ids)
        end
      end
    end

    context 'when the work is a member of collections' do
      let(:work) { FactoryBot.valkyrie_create(:hyrax_work, :as_member_of_multiple_collections) }

      it 'gives collection ids' do
        expect(form.member_of_collection_ids)
          .to contain_exactly(*work.member_of_collection_ids.map(&:id))
      end
    end
  end

  describe '#model_class' do
    it 'is the class of the model' do
      expect(form.model_class).to eq work.class
    end
  end

  describe '#permissions' do
    it 'for a new object has empty permissions' do
      expect(form.permissions).to be_empty
    end

    it 'for a new object prepopulates with empty permissions' do
      expect { form.prepopulate! }
        .not_to change { form.permissions }
        .from(be_empty)
    end

    # Github Issue #4900
    it 'validates an empty nested value' do
      form.validate(
        "permissions_attributes" => {
          "1" => { "type" => "person", "name" => "basic_user@example.com", "access" => "edit" }
        }
      )
    end

    context 'with existing permissions' do
      let(:work) { FactoryBot.valkyrie_create(:hyrax_work, :public) }

      it 'prepopulates with the work permissions' do
        expect { form.prepopulate! }
          .to change { form.permissions }
          .to contain_exactly(have_attributes(agent_name: 'group/public', access: :read))
      end
    end
  end

  describe '#human_readable_type' do
    it 'reads from model' do
      expect(form.human_readable_type).to eq work.human_readable_type
    end

    it 'cannot be overwritten' do
      form.human_readable_type = 'NOPE'

      expect { form.sync }.not_to change { work.human_readable_type }
    end
  end

  describe '#proxy_depositor' do
    let(:user1) { FactoryBot.create(:user).to_s }
    let(:user2) { FactoryBot.create(:user).to_s }
    let(:work) { FactoryBot.valkyrie_create(:hyrax_work, on_behalf_of: user2, proxy_depositor: user1) }

    it 'delegates to model' do
      expect(form.proxy_depositor).to eq user1
    end
  end

  describe '#on_behalf_of' do
    let(:user1) { create(:user).to_s }
    let(:user2) { create(:user).to_s }
    let(:work) { FactoryBot.valkyrie_create(:hyrax_work, on_behalf_of: user2, proxy_depositor: user1) }

    it 'delegates to model' do
      expect(form.on_behalf_of).to eq user2
    end
  end

  describe '#primary_terms' do
    it 'lists the core metadata primary terms' do
      expect(form.primary_terms).to contain_exactly(:title)
    end

    context 'with custom primary terms' do
      subject(:form) { form_class.new(work) }

      let(:form_class) do
        Class.new(Hyrax::Forms::ResourceForm(work.class)) do
          property :my_primary, virtual: true, primary: true
        end
      end

      it 'adds the custom primary terms' do
        expect(form.primary_terms).to contain_exactly(:title, :my_primary)
      end
    end

    context 'with basic metadata' do
      subject(:form) { form_class.new(work) }

      let(:work) { build(:monograph) }

      let(:form_class) do
        Class.new(Hyrax::Forms::ResourceForm(work.class)) do
          include Hyrax::FormFields(:basic_metadata)
        end
      end

      it 'adds the basic metadata primary terms' do
        expect(form.primary_terms)
          .to contain_exactly(:title, :creator, :rights_statement)
      end
    end
  end

  describe '#required?' do
    subject(:form) { form_class.new(work) }

    let(:form_class) do
      Class.new(Hyrax::Forms::ResourceForm(work.class)) do
        property :non_required, virtual: true
      end
    end

    it 'is true for required fields' do
      expect(form.required?(:title)).to eq true
    end

    it 'is false for non-required fields' do
      expect(form.required?(:non_required)).to eq false
    end
  end

  describe '#valid?' do
    subject(:form) { form_class.new(work) }

    let(:form_class) do
      Class.new(Hyrax::Forms::ResourceForm(work.class)) do
        property :non_required, virtual: true
      end
    end

    context 'when any required field is missing' do
      before { form.title = [] }
      it 'fails validation' do
        expect(form.valid?).to be false
      end
    end

    context 'when all required fields are present' do
      # ResourceForm only includes core_metadata which has only title as a required field
      before { form.title = ['My Title'] }
      it 'passes validation' do
        expect(form.valid?).to be true
      end
    end
  end

  describe '#secondary_terms' do
    it 'is empty with only core metadata' do
      expect(form.secondary_terms)
        .to be_empty
    end

    context 'with basic metadata' do
      subject(:form) { form_class.new(work) }

      let(:work) { build(:monograph) }

      let(:form_class) do
        Class.new(Hyrax::Forms::ResourceForm(work.class)) do
          include Hyrax::FormFields(:basic_metadata)
        end
      end

      it 'has secondary terms' do
        expect(form.secondary_terms).to include(:description)
      end

      it 'does not have the primary terms' do
        expect(form.secondary_terms)
          .not_to include(:title, :creator, :rights_statement)
      end
    end
  end

  describe '#sync' do
    context 'when setting an embargo' do
      let(:params) do
        { title: ["Object Under Embargo"],
          embargo_release_date: Date.tomorrow.to_s,
          visibility: "embargo",
          visibility_after_embargo: "open",
          visibility_during_embargo: "restricted" }
      end

      it 'builds an embargo' do
        form.validate(params)

        expect { form.sync }
          .to change { work.embargo }
          .to have_attributes(embargo_release_date: Date.tomorrow.to_s,
                              visibility_after_embargo: "open",
                              visibility_during_embargo: "restricted")
      end

      it 'sets visibility to "during" value' do
        form.validate(params)

        expect(form.visibility).to eq "restricted"
      end
    end

    context 'when setting a lease' do
      let(:params) do
        { title: ["Object Under Lease"],
          lease_expiration_date: Date.tomorrow.to_s,
          visibility: "lease",
          visibility_after_lease: "restricted",
          visibility_during_lease: "open" }
      end

      it 'builds an embargo' do
        form.validate(params)

        expect { form.sync }
          .to change { work.lease }
          .to have_attributes(lease_expiration_date: Date.tomorrow.to_s)
      end

      it 'sets visibility to "during" value' do
        form.validate(params)

        expect(form.visibility).to eq "open"
      end
    end
  end

  describe '#version' do
    context 'when using wings', valkyrie_adapter: :wings_adapter do
      it 'prepopulates as empty before save' do
        form.prepopulate!
        expect(form.version).to eq ''
      end

      context 'with a saved work' do
        let(:work) { FactoryBot.valkyrie_create(:hyrax_work) }

        it 'prepopulates with the etag' do
          af_object = Wings::ActiveFedoraConverter.convert(resource: work)

          form.prepopulate!
          expect(form.version).to eq af_object.etag
        end
      end
    end

    context 'when using a generic valkyrie adapter', valkyrie_adapter: :test_adapter do
      before do
        allow(Hyrax.config).to receive(:disable_wings).and_return(true)
        hide_const("Wings") # disable_wings=true removes the Wings constant
      end
      it 'prepopulates as empty before save' do
        expect(Hyrax.logger).to receive(:info)
          .with(starting_with("trying to prepopulate a lock token for"))
        form.prepopulate!
        expect(form.version).to eq ''
      end

      context 'with a saved work' do
        let(:work) { FactoryBot.valkyrie_create(:hyrax_work) }

        it 'prepopulates empty' do
          expect(Hyrax.logger).to receive(:info)
            .with(starting_with("trying to prepopulate a lock token for"))
          form.prepopulate!
          expect(form.version).to eq ''
        end
      end
    end
  end

  describe '#visibility' do
    it 'can set visibility' do
      form.visibility = 'open'

      expect { form.sync }
        .to change { work.permission_manager.acl.permissions }
        .from(be_empty)
        .to contain_exactly(have_attributes(mode: :read, agent: 'group/public'))
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

    context 'with a work under embargo' do
      let(:work) { FactoryBot.build(:hyrax_work, :under_embargo) }

      it 'defaults to the embargo visibility' do
        expect { form.prepopulate! }
          .to change { form.visibility_after_embargo }
          .from(nil)
          .to('open')
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

    context 'with a work under embargo' do
      let(:work) { FactoryBot.build(:hyrax_work, :under_embargo) }

      it 'defaults to the embargo visibility' do
        expect { form.prepopulate! }
          .to change { form.visibility_during_embargo }
          .from(nil)
          .to('authenticated')
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

    context 'with a work under lease' do
      let(:work) { FactoryBot.build(:hyrax_work, :under_lease) }

      it 'defaults to the lease visibility' do
        expect { form.prepopulate! }
          .to change { form.visibility_after_lease }
          .from(nil)
          .to('authenticated')
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

    context 'with a work under lease' do
      let(:work) { FactoryBot.build(:hyrax_work, :under_lease) }

      it 'defaults to the lease visibility' do
        expect { form.prepopulate! }
          .to change { form.visibility_during_lease }
          .from(nil)
          .to('open')
      end
    end
  end
end
