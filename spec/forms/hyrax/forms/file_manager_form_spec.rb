# frozen_string_literal: true
RSpec.describe Hyrax::Forms::FileManagerForm do
  subject(:form) { described_class.new(work, ability) }
  let(:work) { FactoryBot.build(:generic_work) }
  let(:ability) { :FAKE_ABILITY }

  describe "#id" do
    it "returns the id for the work" do
      expect(subject.id).to eq work.id
    end
  end

  describe "#thumbnail_id" do
    it "returns the work thumbnail_id" do
      expect(subject.thumbnail_id).to eq work.thumbnail_id
    end
  end

  describe "#representative_id" do
    it "returns the work representative_id" do
      expect(subject.representative_id).to eq work.representative_id
    end
  end

  describe "#to_s" do
    it "returns the work to_s" do
      expect(subject.to_s).to eq work.to_s
    end
  end

  describe "#version" do
    it "returns the etag of the work" do
      work.save
      expect(subject.version).to eq work.etag
    end
  end

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

    context "with a Valkyrie work" do
      let(:work) { FactoryBot.valkyrie_create(:hyrax_work, :with_member_file_sets) }
      it "gives presenters" do
        expect(form.member_presenters.length).to eq 2
      end
    end
  end
end
