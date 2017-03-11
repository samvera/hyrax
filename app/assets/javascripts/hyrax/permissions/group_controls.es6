import { Group } from './group'
import { Grant } from './grant'
export class GroupControls {
  /**
   * Initialize the registry
   * @param {jQuery} element the jquery selector for the permissions container
   * @param {Registry} registry the permissions registry
   */
  constructor(element, registry) {
    this.element = element
    this.registry = registry
    this.groupField = this.element.find("#new_group_name_skel")
    this.permissionField = this.element.find("#new_group_permission_skel")

    // add button for new group
    $('#add_new_group_skel').on('click', (e) => this.addNewGroup(e));
  }

  addNewGroup(e) {
    e.preventDefault()
    if (!this.groupValid()) {
      return this.groupField.focus();
    }

    var group_name = this.groupField.val();
    var access = this.permissionField.val();
    var access_label = this.selectedPermission().text();

    if (!this.registry.isPermissionDuplicate(this.groupName())) {
      return this.addError("This group already has a permission.")
    }

    let agent = new Group(group_name)
    let grant = new Grant(agent, access, access_label)
    this.registry.addPermission(grant);
    this.reset();
  }
  // clear out the elements to add more
  reset() {
    this.registry.reset();
    this.groupField.val('');
    this.permissionField.val('none');
  }

  groupName() {
    return this.groupField.val()
  }

  addError(message) {
    this.registry.addError(message);
    this.groupField.val('').focus()
  }

  groupValid() {
    return this.selectedGroupValid() && this.permissionValid()
  }

  selectedGroupValid() {
    return this.selectedGroup().index() !== 0
  }

  selectedGroup() {
    return this.groupField.find(':selected')
  }

  permissionValid() {
    return this.selectedPermission().index() !== 0
  }

  selectedPermission() {
    return this.permissionField.find(':selected')
  }
}
