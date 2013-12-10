// short hand for $(document).ready();
$(function() {

   $('.trophy-class').click(function(){
      var uid=$("#current_user").html();
      $.ajax({
         url:"/users/"+uid+"/trophy",
         type:"post",
         data: "file_id="+this.id,
         success:function(data) {
           gid = data.generic_file_id;
           var oldclass = $('#'+gid).find('i').attr("class");
           if (oldclass.indexOf("trophy-on") != -1){
             $('#'+gid).find('i').attr("title", "Highlight work");
           } else {
             $('#'+gid).find('i').attr("title", "Unhighlight work");
           }

           $('#'+gid).find('i').toggleClass("trophy-on");
           $('#'+gid).find('i').toggleClass("trophy-off");
           if ($('#'+gid).data('removerow')) {
             $('#trophyrow_'+gid).fadeOut(1000, function() {
              $('#trophyrow_'+gid).remove();
              });
           }
         }
      })
    });

}); //closing function at the top of the page


