require 'spec_helper'

describe 'Routes', :type => :routing do
  routes { Sufia::Engine.routes }

  describe 'Homepage' do
    it 'should route the root url to the homepage controller' do
      expect({ get: '/' }).to route_to(controller: 'homepage', action: 'index')
    end
  end

  describe 'GenericWork' do
    it "should route to show" do
      expect({ get: '/works/4' }).to route_to(controller: 'sufia/works/generic_works', action: 'show', id: '4')
    end
  end

  describe 'GenericFile' do
    it 'should route to citation' do
      expect({ get: '/files/1/citation' }).to route_to(controller: 'generic_files', action: 'citation', id: '1')
    end

    it 'should route to stats' do
      expect({ get: '/files/1/stats' }).to route_to(controller: 'generic_files', action: 'stats', id: '1')
    end

    it 'should route to audit' do
      expect({ post: '/files/7/audit' }).to route_to(controller: 'generic_files', action: 'audit', id: '7')
    end

    it 'should route to create' do
      expect({ post: '/files' }).to route_to(controller: 'generic_files', action: 'create')
    end

    it 'should route to new' do
      expect({ get: '/files/new' }).to route_to(controller: 'generic_files', action: 'new')
    end

    it 'should route to edit' do
      expect({ get: '/files/3/edit' }).to route_to(controller: 'generic_files', action: 'edit', id: '3')
    end

    it "should route to show" do
      expect({ get: '/files/4' }).to route_to(controller: 'generic_files', action: 'show', id: '4')
    end

    it "should route to update" do
      expect({ put: '/files/5' }).to route_to(controller: 'generic_files', action: 'update', id: '5')
    end

    it "should route to destroy" do
      expect({ delete: '/files/6' }).to route_to(controller: 'generic_files', action: 'destroy', id: '6')
    end

    it "should *not* route to index" do
      expect({ get: '/files' }).not_to route_to(controller: 'generic_files', action: 'index')
    end
  end

  describe 'Batch' do
    it "should route to edit" do
      expect({ get: '/batches/1/edit' }).to route_to(controller: 'batch', action: 'edit', id: '1')
    end

    it "should route to update" do
      expect({ post: '/batches/2' }).to route_to(controller: 'batch', action: 'update', id: '2')
    end
  end

  describe 'Download' do
    it "should route to show" do
      expect({ get: '/downloads/9' }).to route_to(controller: 'downloads', action: 'show', id: '9')
    end
  end

  describe 'Dashboard' do
    it "should route to dashboard" do
      expect({ get: '/dashboard' }).to route_to(controller: 'dashboard', action: 'index')
    end

      it "should route to dashboard activity" do
      expect({ get: '/dashboard/activity' }).to route_to(controller: 'dashboard', action: 'activity')
    end

    it "should route to my files tab" do
      expect({ get: '/dashboard/files' }).to route_to(controller: 'my/files', action: 'index')
    end

    it "should route to my collections tab" do
      expect({ get: '/dashboard/collections' }).to route_to(controller: 'my/collections', action: 'index')
    end

    it "should route to my highlighted tab" do
      expect({ get: '/dashboard/highlights' }).to route_to(controller: 'my/highlights', action: 'index')
    end

    it "should route to my shared tab" do
      expect({ get: '/dashboard/shares' }).to route_to(controller: 'my/shares', action: 'index')
    end
  end

  describe 'Advanced Search' do
    it "should route to search" do
      expect({ get: '/search' }).to route_to(controller: 'advanced', action: 'index')
    end
  end

  describe 'Authorities' do
    it "should route to query" do
      expect({ get: '/authorities/subject/bio' }).to route_to(controller: 'authorities', action: 'query', model: 'subject', term: 'bio')
    end
  end

  describe 'Users' do
    it 'should route to user trophies' do
      expect({ post: '/users/bob135/trophy' }).to route_to(controller: 'users', action: 'toggle_trophy', id: 'bob135')
    end
    it 'should route to user profile' do
      expect({ get: '/users/bob135' }).to route_to(controller: 'users', action: 'show', id: 'bob135')
    end

    it "should route to edit profile" do
      expect({ get: '/users/bob135/edit' }).to route_to(controller: 'users', action: 'edit', id: 'bob135')
    end

    it "should route to update profile" do
      expect({ put: '/users/bob135' }).to route_to(controller: 'users', action: 'update', id: 'bob135')
    end

    it "should route to user follow" do
      expect({ post: '/users/bob135/follow' }).to route_to(controller: 'users', action: 'follow', id: 'bob135')
    end

    it "should route to user unfollow" do
      expect({ post: '/users/bob135/unfollow' }).to route_to(controller: 'users', action: 'unfollow', id: 'bob135')
    end
  end

  describe "Directory" do
    it "should route to user" do
      expect({ get: '/directory/user/xxx666' }).to route_to(controller: 'directory', action: 'user', uid: 'xxx666')
    end

    it "should route to user attribute" do
      expect({ get: '/directory/user/zzz777/email' }).to route_to(controller: 'directory', action: 'user_attribute', uid: 'zzz777', attribute: 'email')
    end

    it "should route to group and allow periods" do
      expect({ get: '/directory/group/all.staff' }).to route_to(controller: 'directory', action: 'group', cn: 'all.staff')
    end
  end

  describe "Notifications" do
    it "should have index" do
      expect( get: '/notifications').to route_to(controller: 'mailbox', action: 'index')
      expect(notifications_path).to eq '/notifications'
    end
    it "should allow deleting" do
      expect( delete: '/notifications/123').to route_to(controller: 'mailbox', action: 'destroy', id: '123')
      expect(notification_path(123)).to eq '/notifications/123'
    end
    it "should allow deleting all of them" do
      expect( delete: '/notifications/delete_all').to route_to(controller: 'mailbox', action: 'delete_all')
      expect(delete_all_notifications_path).to eq '/notifications/delete_all'
    end
  end

  describe "Contact Form" do
    it "should route to new" do
      expect({ get: '/contact' }).to route_to(controller: 'contact_form', action: 'new')
    end

    it "should route to create" do
      expect({ post: '/contact' }).to route_to(controller: 'contact_form', action: 'create')
    end
  end

  describe "Dynamically edited pages" do
    it "should route to about" do
      expect({ get: '/about' }).to route_to(controller: 'pages', action: 'show', id: 'about_page')
    end
  end

  describe "Static Pages" do
    it "should route to help" do
      expect({ get: '/help' }).to route_to(controller: 'static', action: 'help')
    end

    it "should route to terms" do
      expect({ get: '/terms' }).to route_to(controller: 'static', action: 'terms')
    end

    it "should route to zotero" do
      expect({ get: '/zotero' }).to route_to(controller: 'static', action: 'zotero')
    end

    it "should route to mendeley" do
      expect({ get: '/mendeley' }).to route_to(controller: 'static', action: 'mendeley')
    end

    it "should route to versions" do
      expect({ get: '/versions' }).to route_to(controller: 'static', action: 'versions')
    end

    it "should *not* route a bogus static page" do
      expect({ get: '/awesome' }).not_to route_to(controller: 'static', action: 'awesome')
    end
  end

  describe "Catch-all" do
    it "should route non-existent routes to errors" do
      pending "The default route is turned off in testing, so that errors are raised"
      expect({ get: '/awesome' }).to route_to(controller: 'errors', action: 'routing', error: 'awesome')
    end
  end
end
