require 'spec_helper'

describe 'Routes', type: :routing do
  describe 'Homepage' do
    it 'routes the root url to the welcome controller' do
      expect(get: '/').to route_to(controller: 'welcome', action: 'index')
    end
  end

  describe 'GenericWork' do
    it 'routes to create' do
      expect(post: 'concern/generic_works').to route_to(controller: 'curation_concerns/generic_works', action: 'create')
    end

    it 'routes to new' do
      expect(get: 'concern/generic_works/new').to route_to(controller: 'curation_concerns/generic_works', action: 'new')
    end

    it 'routes to edit' do
      expect(get: 'concern/generic_works/3/edit').to route_to(controller: 'curation_concerns/generic_works', action: 'edit', id: '3')
    end

    it 'routes to show' do
      expect(get: 'concern/generic_works/4').to route_to(controller: 'curation_concerns/generic_works', action: 'show', id: '4')
    end

    it 'routes to update' do
      expect(put: 'concern/generic_works/5').to route_to(controller: 'curation_concerns/generic_works', action: 'update', id: '5')
    end

    it 'routes to destroy' do
      expect(delete: 'concern/generic_works/6').to route_to(controller: 'curation_concerns/generic_works', action: 'destroy', id: '6')
    end

    it '*not*s route to index' do
      expect(get: 'concern/generic_works').not_to route_to(controller: 'curation_concerns/generic_works', action: 'index')
    end

    it 'routes to file_manager' do
      expect(get: 'concern/generic_works/6/file_manager').to route_to(controller: 'curation_concerns/generic_works', action: 'file_manager', id: '6')
    end

    it 'routes to inspect_work' do
      expect(get: 'concern/generic_works/6/inspect_work').to route_to(controller: 'curation_concerns/generic_works', action: 'inspect_work', id: '6')
    end
  end

  describe 'Permissions' do
    it 'routes to confirm' do
      expect(get: '/concern/permissions/1/confirm').to route_to(controller: 'curation_concerns/permissions', action: 'confirm', id: '1')
    end

    it 'routes to copy' do
      expect(post: '/concern/permissions/2/copy').to route_to(controller: 'curation_concerns/permissions', action: 'copy', id: '2')
    end
  end

  describe 'FileSet' do
    it 'routes to create' do
      expect(post: 'concern/container/1/file_sets').to route_to(controller: 'curation_concerns/file_sets', action: 'create', parent_id: '1')
    end

    it 'routes to new' do
      expect(get: 'concern/container/2/file_sets/new').to route_to(controller: 'curation_concerns/file_sets', action: 'new', parent_id: '2')
    end

    it 'routes to edit' do
      expect(get: 'concern/file_sets/3/edit').to route_to(controller: 'curation_concerns/file_sets', action: 'edit', id: '3')
    end

    it 'routes to show' do
      expect(get: 'concern/file_sets/4').to route_to(controller: 'curation_concerns/file_sets', action: 'show', id: '4')
    end

    it 'routes to update' do
      expect(put: 'concern/file_sets/5').to route_to(controller: 'curation_concerns/file_sets', action: 'update', id: '5')
    end

    it 'routes to destroy' do
      expect(delete: 'concern/file_sets/6').to route_to(controller: 'curation_concerns/file_sets', action: 'destroy', id: '6')
    end

    it '*not*s route to index' do
      expect(get: 'concern/file_sets').not_to route_to(controller: 'curation_concerns/file_sets', action: 'index')
    end
  end

  describe 'Download' do
    it 'routes to show' do
      expect(get: '/downloads/9').to route_to(controller: 'downloads', action: 'show', id: '9')
    end
  end

  describe 'WorkflowAction' do
    it 'routes to update' do
      expect(put: 'concern/workflow_actions/5').to route_to(controller: 'curation_concerns/workflow_actions', action: 'update', id: '5')
    end
  end

  describe 'Admin Dashboard' do
    routes { CurationConcerns::Engine.routes }
    it 'routes to the admin dashboard' do
      expect(get: '/admin').to route_to(controller: 'curation_concerns/admin', action: 'index')
    end
  end
end
