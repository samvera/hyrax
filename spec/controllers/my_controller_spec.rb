require 'spec_helper'

describe MyController, :type => :controller do

  it "sets the controller name" do
    expect(controller.controller_name).to eq :my
  end

end
