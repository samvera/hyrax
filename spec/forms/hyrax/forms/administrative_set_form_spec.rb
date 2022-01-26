# frozen_string_literal: true

RSpec.describe Hyrax::Forms::AdministrativeSetForm do
  subject(:form)  { described_class.new(admin_set) }
  let(:admin_set) { Hyrax::AdministrativeSet.new }

  describe '.required_fields' do
    it 'lists required fields' do
      expect(described_class.required_fields)
        .to contain_exactly :title
    end
  end

  describe '#primary_terms' do
    it 'gives "title" as a primary term' do
      expect(form.primary_terms).to contain_exactly(:title, :description)
    end
  end

  describe '#member_ids' do
    it 'populates as empty' do
      expect { form.prepopulate! }
        .not_to change { form.member_ids }
        .from be_empty
    end

    context 'when the admin set is persisted' do
      let(:admin_set) { FactoryBot.valkyrie_create(:hyrax_admin_set) }

      it 'populates as empty' do
        expect { form.prepopulate! }
          .not_to change { form.member_ids }
          .from be_empty
      end

      it 'populates with members' do
        works = [FactoryBot.valkyrie_create(:hyrax_work, admin_set_id: admin_set.id),
                 FactoryBot.valkyrie_create(:hyrax_work, admin_set_id: admin_set.id)]

        expect { form.prepopulate! }
          .to change { form.member_ids }
          .from(be_empty)
          .to contain_exactly(*works.map(&:id))
      end
    end
  end
end
