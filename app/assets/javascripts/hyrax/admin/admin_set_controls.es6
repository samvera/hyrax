export default class {
  constructor(elem) {
    let Participants = require('hyrax/admin/admin_set/participants');
    let participants = new Participants(elem.find('#participants'))
    participants.setup();

    let Visibility = require('hyrax/admin/admin_set/visibility');
    let visibilityTab = new Visibility(elem.find('#visibility'));
    visibilityTab.setup();
  }
}
