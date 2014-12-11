require 'spec_helper'

describe 'generic_files/_permission_form.html.erb', :type => :view do
  let(:gf) {
    stub_model(GenericFile, noid: '123',
        depositor: 'bob',
        resource_type: ['Dataset'])
  }

  before do
    allow(controller).to receive(:current_user).and_return(stub_model(User))
  end

  it "should draw the permissions form without error" do
    render partial: 'generic_files/permission_form.html.erb',  locals: {gf: gf}
    expect(rendered).to have_css("input#new_user_name_skel")
  end

end
