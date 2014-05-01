require 'spec_helper'

describe Worthwhile::GenericWork do
  it "should have a title" do
    subject.title = 'foo'
    expect(subject.title).to eq ['foo']
  end
end
