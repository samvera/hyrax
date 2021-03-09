# frozen_string_literal: true
RSpec.describe Hyrax::Forms::FileManagerForm do
  subject(:form) { described_class.new(work, ability) }
  let(:work) { FactoryBot.build(:generic_work) }
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

    context 'with an AF::Base work' do
      let(:work) { FactoryBot.create(:work_with_files) }

      it 'gives file set presenters' do
        expect(form.member_presenters)
          .to contain_exactly(an_instance_of(Hyrax::FileSetPresenter),
                              an_instance_of(Hyrax::FileSetPresenter))
      end
    end
  end
end
