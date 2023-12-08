# frozen_string_literal: true
RSpec.describe Hyrax::AdminSetService do
  let(:controller) { ::CatalogController.new }
  let(:context) do
    double(current_ability: Ability.new(user),
           repository: controller.blacklight_config.repository,
           blacklight_config: controller.blacklight_config,
           search_state_class: nil)
  end
  let(:service) { described_class.new(context) }
  let(:user) { FactoryBot.create(:user) }

  describe "#search_results", :clean_repo do
    let!(:as1) { FactoryBot.valkyrie_create(:hyrax_admin_set, read_groups: ['public']) }
    let!(:as2) { FactoryBot.valkyrie_create(:hyrax_admin_set, read_groups: ['public']) }
    let!(:as3) { FactoryBot.valkyrie_create(:hyrax_admin_set, edit_users: [user.user_key]) }

    before do
      FactoryBot.valkyrie_create(:hyrax_collection, :public) # this should never be returned.
    end

    context "with read access" do
      let(:access) { :read }

      it "returns three admin sets" do
        expect(service.search_results(access).map(&:id))
          .to contain_exactly(as1.id, as2.id, as3.id)
      end
    end

    context "with edit access" do
      let(:access) { :edit }

      it "returns one admin set" do
        expect(service.search_results(access).map(&:id))
          .to contain_exactly(as3.id)
      end
    end
  end

  context "with injection" do
    subject { service.search_results(access) }

    let(:service) { described_class.new(context, search_builder) }
    let(:access) { :edit }
    let(:search_builder) { double(new: search_builder_instance) }
    let(:search_builder_instance) { double }

    it "calls the injected search builder" do
      expect(search_builder_instance).to receive(:rows).and_return(search_builder_instance)
      expect(search_builder_instance).to receive(:reverse_merge).and_return({})
      subject
    end
  end

  describe '#search_results_with_work_count', :clean_repo do
    subject { service.search_results_with_work_count(access) }

    let(:admin_set_attrs) do
      [
        { id: 'admin_set_1' },
        { id: 'admin_set_2' },
        { id: 'admin_set_3' }
      ]
    end

    let(:file_set_attrs) do
      [
        { id: 'file_1', has_model_ssim: 'FileSet' },
        { id: 'file_2', has_model_ssim: 'FileSet' },
        { id: 'file_3', has_model_ssim: 'FileSet' },
        { id: 'file_4', has_model_ssim: 'FileSet' },
        { id: 'file_5', has_model_ssim: 'FileSet' },
        { id: 'file_6', has_model_ssim: 'FileSet' },
        { id: 'file_7', has_model_ssim: 'FileSet' },
        { id: 'file_8', has_model_ssim: 'FileSet' },
        { id: 'file_9', has_model_ssim: 'FileSet' },
        { id: 'file_10', has_model_ssim: 'FileSet' },
        { id: 'file_11', has_model_ssim: 'FileSet' }
      ]
    end

    let(:work1_attrs) { { id: 'work_1' } }
    let(:work2_attrs) { { id: 'work_2' } }
    let(:work3_attrs) { { id: 'work_3' } }
    let(:work4_attrs) { { id: 'work_4' } }
    let(:work5_attrs) { { id: 'work_5' } }
    let(:work6_attrs) { { id: 'work_6' } }
    let(:work7_attrs) { { id: 'work_7' } }
    let(:work8_attrs) { { id: 'work_8' } }
    let(:work9_attrs) { { id: 'work_9' } }
    let(:work10_attrs) { { id: 'work_10' } }
    let(:work11_attrs) { { id: 'work_11' } }

    let(:work_attrs) { [work1_attrs, work2_attrs, work3_attrs, work4_attrs, work5_attrs, work6_attrs, work7_attrs, work8_attrs, work9_attrs, work10_attrs, work11_attrs] }

    let(:works) do
      [].tap do |result|
        work_attrs.each do |work|
          result << SolrDocument.new(work)
        end
      end
    end

    let(:admin_sets) do
      [].tap do |result|
        admin_set_attrs.each do |admin_set|
          result << SolrDocument.new(admin_set)
        end
      end
    end

    let(:file_sets) do
      [].tap do |result|
        file_set_attrs.each do |file_set|
          result << SolrDocument.new(file_set)
        end
      end
    end

    let(:access) { :read }
    let(:struct) { described_class::SearchResultForWorkCount }

    before do
      allow(service).to receive(:search_results).and_return(admin_sets)
      all_objects = []
      all_objects << works << admin_sets << file_sets
      all_objects.each do |obj|
        Hyrax::SolrService.add(obj)
      end
      Hyrax::SolrService.commit
    end

    context "when there are works and files in the admin set" do
      let(:work1_attrs) { { id: 'work_1', isPartOf_ssim: 'admin_set_1', member_ids_ssim: ['file_1', 'file_3', 'file_4'] } }
      let(:work2_attrs) { { id: 'work_2', isPartOf_ssim: 'admin_set_2', member_ids_ssim: ['file_2'] } }
      let(:work3_attrs) { { id: 'work_3', isPartOf_ssim: 'admin_set_2', member_ids_ssim: ['file_6', 'file_7'] } }
      let(:work4_attrs) { { id: 'work_4', isPartOf_ssim: 'admin_set_3', member_ids_ssim: ['file_8'] } }

      it "returns rows with document in the first column, count of works in second column and count of files in the third column" do
        expect(subject).to eq [struct.new(admin_sets[0], 1, 3), struct.new(admin_sets[1], 2, 3), struct.new(admin_sets[2], 1, 1)]
      end
    end

    context "when there are no files in the admin set" do
      let(:work1_attrs) { { id: 'work_1', isPartOf_ssim: 'admin_set_1', member_ids_ssim: [] } }
      let(:work2_attrs) { { id: 'work_2', isPartOf_ssim: 'admin_set_2', member_ids_ssim: [] } }
      let(:work3_attrs) { { id: 'work_3', isPartOf_ssim: 'admin_set_2', member_ids_ssim: [] } }

      it "returns rows with document in the first column, count of works in second column and count of no files in the third column" do
        expect(subject).to eq [struct.new(admin_sets[0], 1, 0), struct.new(admin_sets[1], 2, 0), struct.new(admin_sets[2], 0, 0)]
      end
    end

    context "when there are more than 10 works in the admin set" do
      let(:work1_attrs) { { id: 'work_1', isPartOf_ssim: 'admin_set_1', member_ids_ssim: ['file_1'] } }
      let(:work2_attrs) { { id: 'work_2', isPartOf_ssim: 'admin_set_1', member_ids_ssim: ['file_2'] } }
      let(:work3_attrs) { { id: 'work_3', isPartOf_ssim: 'admin_set_1', member_ids_ssim: ['file_3'] } }
      let(:work4_attrs) { { id: 'work_4', isPartOf_ssim: 'admin_set_1', member_ids_ssim: ['file_4'] } }
      let(:work5_attrs) { { id: 'work_5', isPartOf_ssim: 'admin_set_1', member_ids_ssim: ['file_5'] } }
      let(:work6_attrs) { { id: 'work_6', isPartOf_ssim: 'admin_set_1', member_ids_ssim: ['file_6'] } }
      let(:work7_attrs) { { id: 'work_7', isPartOf_ssim: 'admin_set_1', member_ids_ssim: ['file_7'] } }
      let(:work8_attrs) { { id: 'work_8', isPartOf_ssim: 'admin_set_1', member_ids_ssim: ['file_8'] } }
      let(:work9_attrs) { { id: 'work_9', isPartOf_ssim: 'admin_set_1', member_ids_ssim: ['file_9'] } }
      let(:work10_attrs) { { id: 'work_10', isPartOf_ssim: 'admin_set_1', member_ids_ssim: ['file_10'] } }
      let(:work11_attrs) { { id: 'work_11', isPartOf_ssim: 'admin_set_1', member_ids_ssim: ['file_11'] } }

      it "returns rows with document in the first column, count of works in second column and count of files in the third column" do
        expect(subject).to eq [struct.new(admin_sets[0], 11, 11), struct.new(admin_sets[1], 0, 0), struct.new(admin_sets[2], 0, 0)]
      end
    end
  end
end
