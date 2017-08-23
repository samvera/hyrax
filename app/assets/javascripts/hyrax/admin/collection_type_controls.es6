// The editor for the CollectionTypeParticipant
// Add search for user/group to the edit an admin set's participants page
import Participants from 'hyrax/admin/collection_type/participants'

export default class {
    constructor(elem) {
        let participants = new Participants(elem.find('#participants'))
        participants.setup();
    }
}
