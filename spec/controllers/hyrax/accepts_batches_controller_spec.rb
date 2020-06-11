# frozen_string_literal: true
class AcceptsBatchesController < ApplicationController
  include Hyrax::Collections::AcceptsBatches
end

RSpec.describe AcceptsBatchesController, type: :controller do
  describe 'batch' do
    it 'accepts batch from parameters' do
      controller.params['batch_document_ids'] = %w[abc xyz]
      expect(controller.batch).to eq(%w[abc xyz])
    end
    describe ':all' do
      let(:current_user) { double(user_key: 'vanessa') }
      let(:mock_service) { instance_double(Hyrax::Collections::SearchService) }

      before do
        doc1 = double(id: 123)
        doc2 = double(id: 456)
        allow(Hyrax::Collections::SearchService).to receive(:new).and_return(mock_service)
        expect(mock_service).to receive(:last_search_documents).and_return([doc1, doc2])
        allow(controller).to receive(:current_user).and_return(current_user)
      end
      it 'adds every document in the current resultset to the batch' do
        controller.params['batch_document_ids'] = 'all'
        expect(controller.batch).to eq([123, 456])
      end
    end
  end

  describe 'should allow filtering for access' do
    let(:allowed) { [1, 2, 3] }
    let(:disallowed) { [5, 6, 7] }

    before do
      subject.batch = allowed + disallowed
    end
    it 'using filter_docs_with_access!' do
      allowed.each { |doc_id| expect(subject).to receive(:can?).with(:foo, doc_id).and_return(true) }
      disallowed.each { |doc_id| expect(subject).to receive(:can?).with(:foo, doc_id).and_return(false) }
      subject.send(:filter_docs_with_access!, :foo)
      expect(flash[:notice]).to eq("You do not have permission to edit the documents: #{disallowed.join(', ')}")
    end
    it 'using filter_docs_with_edit_access!' do
      allowed.each { |doc_id| expect(subject).to receive(:can?).with(:edit, doc_id).and_return(true) }
      disallowed.each { |doc_id| expect(subject).to receive(:can?).with(:edit, doc_id).and_return(false) }
      subject.send(:filter_docs_with_edit_access!)
      expect(flash[:notice]).to eq("You do not have permission to edit the documents: #{disallowed.join(', ')}")
    end
    it 'using filter_docs_with_read_access!' do
      allowed.each { |doc_id| expect(subject).to receive(:can?).with(:read, doc_id).and_return(true) }
      disallowed.each { |doc_id| expect(subject).to receive(:can?).with(:read, doc_id).and_return(false) }
      subject.send(:filter_docs_with_read_access!)
      expect(flash[:notice]).to eq("You do not have permission to edit the documents: #{disallowed.join(', ')}")
    end
    it "and be sassy if you didn't select anything" do
      subject.batch = []
      subject.send(:filter_docs_with_read_access!)
      expect(flash[:notice]).to eq('Select something first')
    end
  end

  it 'checks for empty' do
    controller.batch = %w[77826928 94120425]
    expect(controller.check_for_empty_batch?).to eq(false)
    controller.batch = []
    expect(controller.check_for_empty_batch?).to eq(true)
  end
end
