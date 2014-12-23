require 'spec_helper'

describe 'generic_files/_permission_form.html.erb', :type => :view do
  let(:generic_file) {
    stub_model(GenericFile, noid: '123',
        depositor: 'bob',
        resource_type: ['Dataset'])
  }

  before do
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    allow(generic_file).to receive(:permissions).and_return([])
    form_for(generic_file, url: '/update') do |f|
      @f = f
    end
  end

  it "should draw the permissions form without error" do
    render 'generic_files/permission_form.html.erb', f: @f
    expect(rendered).to have_css("input#new_user_name_skel")
  end

end
