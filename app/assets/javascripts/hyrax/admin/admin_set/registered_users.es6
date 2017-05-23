export default class {
    // Behaviors for the "Allow all registered users" button.
    constructor(button, agents, groupForm) {
      this.groupForm = groupForm
      this.allUsersButton = button
      this.agents = agents
    }

    // If a row for registered users exists, hide the button
    // Otherwise add behaviors for when the button is clicked
    setup() {
      if (this.hasRegisteredUsers()) {
        this.allUsersButton.hide()
      } else {
        this.allUsersButton.on('click', () => this.addAllUsersAsDepositors())
      }
    }

    // The DOM has some data attributes written that indicate the agent_id
    // Check to see if any of them are for the 'registered' group.
    hasRegisteredUsers() {
      return this.agents.filter((_i, elem) => { return elem == 'registered' }).length > 0
    }

    // Grant deposit access to the 'registered' group
    addAllUsersAsDepositors() {
      this.groupForm.setAgent('registered')
      this.groupForm.setAccess('deposit')
      this.groupForm.submitForm()
    }
}
