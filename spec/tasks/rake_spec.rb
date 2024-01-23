# frozen_string_literal: true
require 'rake'

RSpec.describe "Rake tasks" do
  describe "hyrax:embargo:deactivate_expired", :clean_repo do
    let!(:active) do
      [FactoryBot.valkyrie_create(:hyrax_work, :under_embargo),
       FactoryBot.valkyrie_create(:hyrax_work, :under_embargo)]
    end

    let!(:expired) do
      [FactoryBot.valkyrie_create(:hyrax_work, :with_expired_enforced_embargo),
       FactoryBot.valkyrie_create(:hyrax_work, :with_expired_enforced_embargo)]
    end

    before do
      load_rake_environment [File.expand_path("../../../lib/tasks/embargo_lease.rake", __FILE__)]
    end

    it "adds embargo history for expired embargoes" do
      expect { run_task 'hyrax:embargo:deactivate_expired' }
        .to change {
          Hyrax.query_service.find_many_by_ids(ids: expired.map(&:id))
               .map { |work| work.embargo.embargo_history }
        }
        .from(contain_exactly(be_empty, be_empty))
        .to(contain_exactly([start_with('An expired embargo was deactivated')],
                            [start_with('An expired embargo was deactivated')]))
    end

    it "updates the persisted work ACLs for expired embargoes" do
      expect { run_task 'hyrax:embargo:deactivate_expired' }
        .to change {
          Hyrax.query_service.find_many_by_ids(ids: expired.map(&:id))
               .map { |work| work.permission_manager.read_groups.to_a }
        }
        .from([contain_exactly('registered'), contain_exactly('registered')])
        .to([include('public'), include('public')])
    end

    it "updates the persisted work visibility for expired embargoes" do
      expect { run_task 'hyrax:embargo:deactivate_expired' }
        .to change {
          Hyrax.query_service.find_many_by_ids(ids: expired.map(&:id))
               .map(&:visibility)
        }
        .from(['authenticated', 'authenticated'])
        .to(['open', 'open'])
    end

    it "does not update visibility for works with active embargoes" do
      expect { run_task 'hyrax:embargo:deactivate_expired' }
        .not_to change {
          Hyrax.query_service.find_many_by_ids(ids: active.map(&:id))
               .map(&:visibility)
        }
        .from(['authenticated', 'authenticated'])
    end

    it "removes the work from Hyrax::EmbargoHelper.assets_under_embargo" do
      helper = Class.new { include Hyrax::EmbargoHelper }

      # this helper is the source of truth for listing currently enforced embargoes for the UI
      expect { run_task 'hyrax:embargo:deactivate_expired' }
        .to change { helper.new.assets_under_embargo }
        .from(contain_exactly(*(active + expired).map { |work| have_attributes(id: work.id) }))
        .to(contain_exactly(*active.map { |work| have_attributes(id: work.id) }))
    end
  end

  describe "hyrax:user:list_emails" do
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }

    before do
      load_rake_environment [File.expand_path("../../../lib/tasks/hyrax_user.rake", __FILE__)]
    end

    it "creates a file" do
      run_task "hyrax:user:list_emails"
      expect(File).to exist("user_emails.txt")
      expect(IO.read("user_emails.txt")).to include(user1.email, user2.email)
      File.delete("user_emails.txt")
    end

    it "creates a file I give it" do
      run_task "hyrax:user:list_emails", "abc123.txt"
      expect(File).not_to exist("user_emails.txt")
      expect(File).to exist("abc123.txt")
      expect(IO.read("abc123.txt")).to include(user1.email, user2.email)
      File.delete("abc123.txt")
    end
  end

  describe 'hyrax:collections', :clean_repo do
    describe ':update_collection_type_global_ids' do
      before do
        load_rake_environment [File.expand_path('../../../lib/tasks/collection_type_global_id.rake', __FILE__)]
      end

      context 'with no collections' do
        it 'outputs that 0 collections were updated' do
          run_task 'hyrax:collections:update_collection_type_global_ids'
        end
      end

      context 'with collections' do
        let(:collection_type) { FactoryBot.create(:collection_type) }
        let(:other_collection_type) { FactoryBot.create(:collection_type) }

        let(:collections_with_legacy_gids) do
          [FactoryBot.valkyrie_create(:pcdm_collection, collection_type_gid: "gid://internal/sometext/#{collection_type.id}"),
           FactoryBot.valkyrie_create(:pcdm_collection, collection_type_gid: "gid://internal/sometext/#{other_collection_type.id}")]
        end

        before do
          3.times do
            FactoryBot.valkyrie_create(:pcdm_collection, collection_type_gid: collection_type.to_global_id)
            FactoryBot.valkyrie_create(:pcdm_collection, collection_type_gid: other_collection_type.to_global_id)
          end
        end

        it 'updates collections to use standard GlobalId URI' do
          expect { run_task 'hyrax:collections:update_collection_type_global_ids' }
            .to change { collections_with_legacy_gids.map { |col| Hyrax.query_service.find_by(id: col.id).collection_type_gid } }
            .to eq [collection_type.to_global_id.to_s, other_collection_type.to_global_id.to_s]
        end
      end
    end
  end
end
