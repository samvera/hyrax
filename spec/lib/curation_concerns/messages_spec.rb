require 'spec_helper'

describe CurationConcerns::Messages do
  let(:message) do
    TestClass.new
  end

  before do
    class TestClass
      include CurationConcerns::Messages
    end
  end

  after do
    Object.send(:remove_const, :TestClass)
  end

  let(:batch_id) { '1' }
  let(:single) { double(to_param: '1', to_s: 'File 1') }
  let(:multiple) { [double(to_param: '1', to_s: 'File 1'), double(to_param: '2', to_s: 'File 2'), double(to_param: '3', to_s: 'File 3')] }
  let(:file_list) { "<a href='/concern/generic_files/1'>File 1</a>, <a href='/concern/generic_files/2'>File 2</a>, <a href='/concern/generic_files/3'>File 3</a>" }

  describe 'message subjects' do
    it 'provides a subject for a success message' do
      expect(message.success_subject).to eq('Batch upload complete')
    end
    it 'provides a subject for a failure message' do
      expect(message.failure_subject).to eq('Batch upload permission denied')
    end
  end

  describe '#single_success' do
    it 'renders a success message for a single file' do
      node = Capybara::Node::Simple.new(message.single_success(batch_id, single))
      expect(node).to have_selector("span[id=\"ss-1\"]", text: 'File 1 has been saved.')
      expect(node).to have_selector("a[href=\"/concern/generic_files/1\"]")
    end
  end

  describe '#multiple_success' do
    it 'renders a success message for multiple files' do
      node = Capybara::Node::Simple.new(message.multiple_success(batch_id, multiple))
      expect(node).to have_selector("span[id=\"ss-1\"]", text: 'These files have been saved.')
      expect(node).to have_selector("a[data-content=\"#{file_list}\"][rel=\"popover\"][data-title=\"Files uploaded successfully\"]")
    end
  end

  describe '#single_failure' do
    it 'renders a failure message for a single file' do
      node = Capybara::Node::Simple.new(message.single_failure(batch_id, single))
      expect(node).to have_selector("span[id=\"ss-1\"]", text: 'File 1 could not be updated. You do not have sufficient privileges to edit it.')
      expect(node).to have_selector("a[href=\"/concern/generic_files/1\"]")
    end
  end

  describe '#multiple_failure' do
    it 'renders a failure message for multiple files' do
      node = Capybara::Node::Simple.new(message.multiple_failure(batch_id, multiple))
      expect(node).to have_selector("span[id=\"ss-1\"]", text: 'These files could not be updated. You do not have sufficient privileges to edit them.')
      expect(node).to have_selector("a[data-content=\"#{file_list}\"][rel=\"popover\"][data-title=\"Files failed\"]")
    end
  end

  describe '#file_list' do
    it 'replaces double-quotes with single quotes' do
      expect(message.file_list(multiple)).to eq(file_list)
    end
  end
end
