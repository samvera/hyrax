require 'spec_helper'

describe Sufia::Breadcrumbs do  

  let(:crumbs) do
    TestClass.new
  end

  let(:sufia) do
    Sufia::Engine.routes.url_helpers
  end

  before do
    class TestClass
      attr_accessor :trail, :request
      include Sufia::Breadcrumbs
      def initialize
        @trail = []
        @request = true # avoids the allow_message_expectations_on_nil warning
      end
      def add_breadcrumb text, link
        @trail << [text, link]
      end
    end
    allow_any_instance_of(TestClass).to receive(:sufia).and_return(sufia)
  end

  describe "#default_trail" do
    context "when the user is logged in" do
      before do
        crumbs.stub(:user_signed_in?) { true }
      end
      specify "the default trail is nil" do
        expect(crumbs.default_trail).to eql([[I18n.t('sufia.dashboard.title'), sufia.dashboard_index_path]])
      end
    end
    context "when there is no user" do
      before do
        crumbs.stub(:user_signed_in?) { false }
      end
      specify "the default trail is nil" do
        expect(crumbs.default_trail).to be_nil
      end
    end
  end

  describe "#trail_from_referer" do
    context "when coming from the catalog" do
      let(:referer) { "http://...catalog/" }
      before do
        allow(crumbs.request).to receive(:referer).and_return(referer)
      end
      specify "the trail goes back to the search" do
        expect(crumbs.trail_from_referer).to eql([[I18n.t('sufia.bread_crumb.search_results'), referer]])
      end
    end
    context "when coming from the dashboard" do
      before do
        allow(crumbs.request).to receive(:referer).and_return("http://...dashboard/")
        crumbs.stub(:user_signed_in?) { true }
      end
      specify "the trail goes back to the user's files" do
        allow(crumbs).to receive(:controller_name).and_return("my/files")
        expect(crumbs.trail_from_referer.first).to eql([I18n.t('sufia.dashboard.title'), sufia.dashboard_index_path])
        expect(crumbs.trail_from_referer.last).to eql([I18n.t('sufia.dashboard.my.files'), sufia.dashboard_files_path])
      end
      specify "the trail goes back to the user's collections" do
        allow(crumbs).to receive(:controller_name).and_return("my/collections")
        expect(crumbs.trail_from_referer.first).to eql([I18n.t('sufia.dashboard.title'), sufia.dashboard_index_path])
        expect(crumbs.trail_from_referer.last).to eql([I18n.t('sufia.dashboard.my.collections'), sufia.dashboard_collections_path])
      end
      specify "the trail goes back to the user's files when on the batch edit page" do
        allow(crumbs).to receive(:controller_name).and_return("batch_edit")
        expect(crumbs.trail_from_referer.first).to eql([I18n.t('sufia.dashboard.title'), sufia.dashboard_index_path])
        expect(crumbs.trail_from_referer.last).to eql([I18n.t('sufia.dashboard.my.files'), sufia.dashboard_files_path])
      end
    end
  end

end
