export default class {
  constructor(elem) {
    this.user = elem.find('#user-participants-form input[type=text]')
  }

  setup() {
    this.user.userSearch();
  }
}
