# frozen_string_literal: true
RSpec.describe Hyrax::PermissionTemplateApplicator do
  subject(:applicator) { described_class.new(template: template) }
  let(:manage_groups)  { ['edit_group_1', 'edit_group_2'] }
  let(:manage_users)   { [FactoryBot.create(:user).user_key, FactoryBot.create(:user).user_key] }
  let(:template)       { :not_a_template }
  let(:view_groups)    { ['read_group_1', 'read_group_2'] }
  let(:view_users)     { [FactoryBot.create(:user).user_key, FactoryBot.create(:user).user_key] }
  let(:work)           { FactoryBot.build(:hyrax_work) }

  describe '.apply' do
    it 'initializes with template' do
      expect(described_class.apply(template))
        .to have_attributes(template: template)
    end
  end

  describe '#apply_to' do
    let(:template) do
      FactoryBot.create(:permission_template,
                        manage_groups: manage_groups,
                        manage_users: manage_users,
                        view_groups: view_groups,
                        view_users: view_users)
    end

    it 'applies edit groups' do
      edit_after_application = work.edit_groups + manage_groups

      expect { applicator.apply_to(model: work) }
        .to change { work.edit_groups }
        .to contain_exactly(*edit_after_application)
    end

    it 'applies edit users' do
      edit_after_application = work.edit_users + manage_users

      expect { applicator.apply_to(model: work) }
        .to change { work.edit_users }
        .to contain_exactly(*edit_after_application)
    end

    it 'applies read groups' do
      read_after_application = work.read_groups + view_groups

      expect { applicator.apply_to(model: work) }
        .to change { work.read_groups }
        .to contain_exactly(*read_after_application)
    end

    it 'applies read users' do
      read_after_application = work.read_users + view_users

      expect { applicator.apply_to(model: work) }
        .to change { work.read_users }
        .to contain_exactly(*read_after_application)
    end
  end

  describe '#template' do
    let(:new_template) { :not_another_template }

    it 'has a template attribute' do
      expect { applicator.template = new_template }
        .to change { applicator.template }
        .from(template)
        .to new_template
    end
  end
end
