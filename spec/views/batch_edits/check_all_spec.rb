require 'spec_helper'

describe 'Check All' do
  before (:all) do
    @document_list = ['a','b','c']
    @batch_size_on_other_page = 0
    @max_batch_size = 100
  end

  it 'should render batch edits actions' do
    controller.stub(:controller_name).and_return('batch_edits')
    controller.prepend_view_path "app/views/batch_edits"
    html = render partial: 'batch_edits/check_all'
    html.should have_selector("li[data-behavior='batch-edit-select-abc']")
  end

  it 'should render dashboard actions' do
    controller.stub(:controller_name).and_return('dashboard')
    controller.prepend_view_path "app/views/dashboard"
    html = render partial: 'batch_edits/check_all'
    html.should have_selector("li[data-behavior='batch-edit-select-none']")
    html.should have_selector("li[data-behavior='batch-edit-select-page']")
  end
end
