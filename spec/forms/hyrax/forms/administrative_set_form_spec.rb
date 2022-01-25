# frozen_string_literal: true

RSpec.describe Hyrax::Forms::AdministrativeSetForm do
  subject(:form)   { described_class.new(adminset) }
  let(:adminset) { FactoryBot.build(:hyrax_admin_set) }

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
    it 'for a new object has empty membership' do
      expect(form.member_ids).to be_empty
    end

    it 'casts to an array' do
      expect { form.validate(member_ids: '123') }
        .to change { form.member_ids }
        .to contain_exactly('123')
    end

    context 'when the object has members' do
      let(:adminset) { FactoryBot.build(:hyrax_admin_set, :with_member_works) }

      it 'gives member work ids' do
        expect(form.member_ids).to contain_exactly(*adminset.member_ids.map(&:id))
      end
    end
  end
end
