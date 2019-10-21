import RegisteredUsers from './registered_users'
import GroupParticipants from './group_participants'

export default class {
  // Adds autocomplete to the user search function and enables the
  // "Allow all registered users" button.
  constructor(elem) {
    this.userField = elem.find('#user-participants-form input[type=text]')

    let button = elem.find('button[data-behavior="add-registered-users"]')
    let agents = elem.find('[data-agent]').map((_i, field) => { return field.getAttribute('data-agent') })
    let groupParticipants = new GroupParticipants(elem.find('#group-participants-form'))
    this.registeredUsersButton = new RegisteredUsers(button, agents, groupParticipants)
  }

  setup() {
    this.userField.userSearch()
    this.registeredUsersButton.setup()
  }
}
