# frozen_string_literal: true
RSpec.describe Hyrax::Forms::FileManagerForm do
  subject(:form) { described_class.new(work, ability) }
  let(:work) { FactoryBot.build(:work) }
  let(:ability) { :FAKE_ABILITY }

  describe "#member_presenters" do
    context 'with a custom member presenter factory' do
      subject(:form) { described_class.new(work, ability, member_factory: member_factory) }

      let(:member_factory) do
        Class.new(Hyrax::MemberPresenterFactory) do
          def member_presenters
            [:some, :member, :presenters]
          end
        end
      end

      it "is delegated to the MemberPresenterFactory" do
        expect(form.member_presenters).to eq [:some, :member, :presenters]
      end
    end
  end
end
