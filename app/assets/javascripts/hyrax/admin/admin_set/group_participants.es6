export default class {
   constructor(elem) {
     this.form = elem
   }

   // Fill in the group agent field with the given value
   setAgent(agent) {
       this.form.find('#permission_template_access_grants_attributes_0_agent_id').val(agent)
   }

   // Fill in the group access select box with the given value
   setAccess(access) {
       this.form.find('#permission_template_access_grants_attributes_0_access').val(access)
   }

   // Submit the group participants form
   submitForm() {
       this.form.submit()
   }
}
