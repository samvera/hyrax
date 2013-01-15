// short hand for $(document).ready();
$(function() {

   $('.trophy-class').click(function(){
      var uid=$("#current_user").html();
      $.ajax({
         url:"/users/"+uid+"/trophy",
         type:"post",
         data: "file_id="+this.id,
         success:function(data) {
           var oldclass = $('#'+data.trophy.generic_file_id).find('i').attr("class");
           if (oldclass.indexOf("trophy-on") != -1){
             $('#'+data.trophy.generic_file_id).find('i').attr("title", "Highlight work");
           } else {
             $('#'+data.trophy.generic_file_id).find('i').attr("title", "Unhighlight work");
           }

           $('#'+data.trophy.generic_file_id).find('i').toggleClass("trophy-on");
           $('#'+data.trophy.generic_file_id).find('i').toggleClass("trophy-off");
         }
      })
    });

}); //closing function at the top of the page


