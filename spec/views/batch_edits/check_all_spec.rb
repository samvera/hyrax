require 'spec_helper'

describe 'Check All', :type => :view do
  before (:all) do
    @document_list = ['a','b','c']
    @batch_size_on_other_page = 0
    @max_batch_size = 100
  end

  it 'should render batch edits actions' do
    allow(controller).to receive(:controller_name).and_return('batch_edits')
    controller.prepend_view_path "app/views/batch_edits"
    html = render partial: 'batch_edits/check_all'
    expect(html).to have_selector("li[data-behavior='batch-edit-select-abc']")
  end

  it 'should render actions for my items' do
    allow(controller).to receive(:controller_name).and_return('my')
    controller.prepend_view_path "app/views/my"
    html = render partial: 'batch_edits/check_all'
    expect(html).to have_selector("li[data-behavior='batch-edit-select-none']")
    expect(html).to have_selector("li[data-behavior='batch-edit-select-page']")
  end
end
