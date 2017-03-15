import { Person } from './person'
import { Grant } from './grant'
export class UserControls {
  /**
   * Initialize the registry
   * @param {jQuery} element the jquery selector for the permissions container
   * @param {Registry} registry the permissions registry
   */
  constructor(element, registry) {
    this.element = element
    this.registry = registry
    this.depositor = $('#file_owner').data('depositor')
    this.userField = this.element.find("#new_user_name_skel")
    this.permissionField = this.element.find("#new_user_permission_skel")

    // Attach the user search select2 box to the permission form
    this.userField.userSearch()

    // add button for new user
    $('#add_new_user_skel').on('click', (e) => this.addNewUser(e));
  }

  addNewUser(e) {
    e.preventDefault();

    if (!this.userValid()) {
      return this.userField.focus();
    }

    if (this.selectedUserIsDepositor()) {
      return this.addError("Cannot change depositor permissions.")
    }

    if (!this.registry.isPermissionDuplicate(this.userName())) {
      return this.addError("This user already has a permission.")
    }

    var access = this.permissionField.val();
    var access_label = this.selectedPermission().text();
    let agent = new Person(this.userName())
    let grant = new Grant(agent, access, access_label)
    this.registry.addPermission(grant);
    this.reset();
  }

  // clear out the elements to add more
  reset() {
    this.registry.reset();
    this.userField.select2('val', '');
    this.permissionField.val('none');
  }

  userName() {
    return this.userField.val()
  }

  addError(message) {
    this.registry.addError(message);
    this.userField.val('').focus()
  }

  selectedUserIsDepositor() {
    return this.userName() === this.depositor
  }

  userValid() {
    return this.userNameValid() && this.permissionValid()
  }

  userNameValid() {
    return this.userName() !== ""
  }

  permissionValid() {
    return this.selectedPermission().index() !== 0
  }

  selectedPermission() {
    return this.permissionField.find(':selected')
  }
}
