describe 'Routes', type: :routing do
  routes { Sufia::Engine.routes }

  describe 'Homepage' do
    it 'routes the root url to the homepage controller' do
      expect(get: '/').to route_to(controller: 'sufia/homepage', action: 'index')
    end
  end

  describe "Audit" do
    it 'routes to audit' do
      expect(post: '/concern/file_sets/7/audit').to route_to(controller: 'curation_concerns/audits', action: 'create', file_set_id: '7')
    end
  end

  describe "BatchUpload" do
    context "without a batch" do
      routes { Sufia::Engine.routes }
      it 'routes to create' do
        expect(post: '/batch_uploads').to route_to(controller: 'sufia/batch_uploads', action: 'create')
      end

      it "routes to new" do
        expect(get: '/batch_uploads/new').to route_to(controller: 'sufia/batch_uploads', action: 'new')
      end
    end
  end

  describe 'FileSet' do
    context "main app routes" do
      routes { Rails.application.routes }

      context "with a file_set" do
        it 'routes to create' do
          expect(post: '/concern/container/12/file_sets').to route_to(controller: 'curation_concerns/file_sets', action: 'create', parent_id: '12')
        end

        it 'routes to new' do
          expect(get: '/concern/container/12/file_sets/new').to route_to(controller: 'curation_concerns/file_sets', action: 'new', parent_id: '12')
        end
      end

      it 'routes to edit' do
        expect(get: '/concern/file_sets/3/edit').to route_to(controller: 'curation_concerns/file_sets', action: 'edit', id: '3')
      end

      it "routes to show" do
        expect(get: '/concern/file_sets/4').to route_to(controller: 'curation_concerns/file_sets', action: 'show', id: '4')
      end

      it "routes to update" do
        expect(put: '/concern/file_sets/5').to route_to(controller: 'curation_concerns/file_sets', action: 'update', id: '5')
      end

      it "routes to destroy" do
        expect(delete: '/concern/file_sets/6').to route_to(controller: 'curation_concerns/file_sets', action: 'destroy', id: '6')
      end

      it "doesn't route to index" do
        expect(get: '/concern/file_sets').not_to route_to(controller: 'curation_concerns/file_sets', action: 'index')
      end
    end
  end

  describe 'Download' do
    routes { Rails.application.routes }
    it "routes to show" do
      expect(get: '/downloads/9').to route_to(controller: 'downloads', action: 'show', id: '9')
    end
  end

  describe 'Dashboard' do
    it "routes to dashboard" do
      expect(get: '/dashboard').to route_to(controller: 'dashboard', action: 'index')
    end

    it "routes to dashboard activity" do
      expect(get: '/dashboard/activity').to route_to(controller: 'dashboard', action: 'activity')
    end

    it "routes to my works tab" do
      expect(get: '/dashboard/works').to route_to(controller: 'my/works', action: 'index')
    end

    it "routes to my collections tab" do
      expect(get: '/dashboard/collections').to route_to(controller: 'my/collections', action: 'index')
    end

    it "routes to my highlighted tab" do
      expect(get: '/dashboard/highlights').to route_to(controller: 'my/highlights', action: 'index')
    end

    it "routes to my shared tab" do
      expect(get: '/dashboard/shares').to route_to(controller: 'my/shares', action: 'index')
    end
  end

  describe 'Advanced Search' do
    it "routes to search" do
      expect(get: '/search').to route_to(controller: 'advanced', action: 'index')
    end
  end

  describe 'Authorities' do
    it "routes to query" do
      expect(get: '/authorities/subject/bio').to route_to(controller: 'authorities', action: 'query', model: 'subject', term: 'bio')
    end
  end

  describe 'Users' do
    it 'routes to user trophies' do
      expect(post: '/users/bob135/trophy').to route_to(controller: 'users', action: 'toggle_trophy', id: 'bob135')
    end
    it 'routes to user profile' do
      expect(get: '/users/bob135').to route_to(controller: 'users', action: 'show', id: 'bob135')
    end

    it "routes to edit profile" do
      expect(get: '/users/bob135/edit').to route_to(controller: 'users', action: 'edit', id: 'bob135')
    end

    it "routes to update profile" do
      expect(put: '/users/bob135').to route_to(controller: 'users', action: 'update', id: 'bob135')
    end

    it "routes to user follow" do
      expect(post: '/users/bob135/follow').to route_to(controller: 'users', action: 'follow', id: 'bob135')
    end

    it "routes to user unfollow" do
      expect(post: '/users/bob135/unfollow').to route_to(controller: 'users', action: 'unfollow', id: 'bob135')
    end
  end

  describe "Directory" do
    it "routes to user" do
      expect(get: '/directory/user/xxx666').to route_to(controller: 'directory', action: 'user', uid: 'xxx666')
    end

    it "routes to user attribute" do
      expect(get: '/directory/user/zzz777/email').to route_to(controller: 'directory', action: 'user_attribute', uid: 'zzz777', attribute: 'email')
    end

    it "routes to group and allow periods" do
      expect(get: '/directory/group/all.staff').to route_to(controller: 'directory', action: 'group', cn: 'all.staff')
    end
  end

  describe "Notifications" do
    it "has index" do
      expect(get: '/notifications').to route_to(controller: 'mailbox', action: 'index')
      expect(notifications_path).to eq '/notifications'
    end
    it "allows deleting" do
      expect(delete: '/notifications/123').to route_to(controller: 'mailbox', action: 'destroy', id: '123')
      expect(notification_path(123)).to eq '/notifications/123'
    end
    it "allows deleting all of them" do
      expect(delete: '/notifications/delete_all').to route_to(controller: 'mailbox', action: 'delete_all')
      expect(delete_all_notifications_path).to eq '/notifications/delete_all'
    end
  end

  describe "Contact Form" do
    it "routes to new" do
      expect(get: '/contact').to route_to(controller: 'contact_form', action: 'new')
    end

    it "routes to create" do
      expect(post: '/contact').to route_to(controller: 'contact_form', action: 'create')
    end
  end

  describe "Dynamically edited pages" do
    it "routes to about" do
      expect(get: '/about').to route_to(controller: 'pages', action: 'show', id: 'about_page')
    end
  end

  describe "Static Pages" do
    it "routes to help" do
      expect(get: '/help').to route_to(controller: 'static', action: 'help')
    end

    it "routes to terms" do
      expect(get: '/terms').to route_to(controller: 'static', action: 'terms')
    end

    it "routes to zotero" do
      expect(get: '/zotero').to route_to(controller: 'static', action: 'zotero')
    end

    it "routes to mendeley" do
      expect(get: '/mendeley').to route_to(controller: 'static', action: 'mendeley')
    end

    it "routes to versions" do
      expect(get: '/versions').to route_to(controller: 'static', action: 'versions')
    end

    it "*not*s route a bogus static page" do
      expect(get: '/awesome').not_to route_to(controller: 'static', action: 'awesome')
    end
  end

  describe "Catch-all" do
    it "routes non-existent routes to errors" do
      pending "The default route is turned off in testing, so that errors are raised"
      expect(get: '/awesome').to route_to(controller: 'errors', action: 'routing', error: 'awesome')
    end
  end

  describe 'main app routes' do
    routes { Rails.application.routes }

    describe 'GenericWork' do
      it "routes to show" do
        expect(get: '/concern/generic_works/4').to route_to(controller: 'curation_concerns/generic_works', action: 'show', id: '4')
      end
    end
  end
end
