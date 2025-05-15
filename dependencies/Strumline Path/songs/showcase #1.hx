//a
return disableScript();

import BezierSegment;
import BezierSegments;

import funkin.game.Note;

function postCreate() {
    // for (strumline in strumLines.members) {
    //     strumline.notes.limit = 2000;
    // }
}

function onStrumPathGenerated(strum) {
    var segments = strum.extra.get("bezierSegments");

    // uh don't do it
    // segments.addSegment(new BezierSegment(FlxPoint.get(0, -200), FlxPoint.get(0, 500), FlxPoint.get(0, 1000)), 0);
    // strum.extra.set("segments_speedMult", 0.5);
}

function onStrumPathUpdate(event) {
    var segments = event.data.segments;

    var strum = event.data.strum;
    var strumIdx = event.data._strumIdx;

    var strumLine = event.data.strumLine;
    var strumLineIdx = event.data._strumLineIdx;

    var endingSegment = segments.getSegment(segments.segments.length-1);

    var offset = (strumLine.members.length % 2 != 0) ? 0 : 0.5;
    
    endingSegment.end.x = ((Note.swagWidth * strumLine.strumScale) * (((strumLine.members.length/2)-offset) - strumIdx));
    endingSegment.end.y = FlxG.height - strum.height + (strum.height * 0.5) + 15;

    endingSegment.control.y = (endingSegment.end.y * 1);
}