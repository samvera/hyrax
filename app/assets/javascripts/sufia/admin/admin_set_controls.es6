export default class {
  constructor(elem) {
    let Participants = require('sufia/admin/admin_set/participants');
    let participants = new Participants(elem.find('#participants'))
    participants.setup();
  }
}
