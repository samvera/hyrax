function initialize_audio() {

    var test_audio= document.createElement("audio") //try and create sample audio element
    var audiosupport= (test_audio.play)? true : false

    if (audiosupport){
        $('audio').each(function() {
            this.controls = true;
        });
    }else {
        $('audio').each(function() {
            $(this).attr("preload","auto");
        });
        audiojs.events.ready(function() {
          var as = audiojs.createAll({
                 imageLocation: '/assets/player-graphics.gif',
                 swfLocation: '/assets/audiojs.swf'
                 });

          // remove html 5 player from veiw on firefox and safari
          $('.audiojs').addClass('no-audio-background')
          $('.audiojs .play-pause').addClass('hide')
          $('.audiojs .scrubber').addClass('hide')
          $('.audiojs .time').addClass('hide')

        });
    };
}
