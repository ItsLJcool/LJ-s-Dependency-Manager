//a

function onStrumPathUpdate(event) {
    var segment = event.data.segment;
    var strum = event.data.strum;
    segment.control.x = Math.sin((Conductor.songPosition*0.001)*4)*150;
}