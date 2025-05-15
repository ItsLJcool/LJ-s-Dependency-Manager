
import BezierSegment;
import BezierSegments;

function postCreate() {
    for (strumline in strumLines.members) {
        strumline.notes.limit = 2000;
    }
    FlxG.mouse.visible = true;
}

var xVal = 150;
function onStrumPathGenerated(strum) {
    var segments = strum.extra.get("bezierSegments");
    strum.extra.set("segments_speedMult", 1.5);
    strum.extra.set("draw_arrowline", false);

    var endingSegment = segments.segments[segments.segments.length-1];
    endingSegment.end.y = FlxG.height - strum.height + (strum.height * 0.5) + 15;
    var newSegments = splitBezierSegment(endingSegment, 2);
    newSegments.reverse();

    segments.segments = newSegments;
}

function update(elapsed:Float) {
    xVal = Math.sin((Conductor.songPosition*0.001)*4) * 150;
}

function onStrumPathUpdate(event) {
    var segments = event.data.segments;

    var strum = event.data.strum;
    var strumIdx = event.data._strumIdx;

    var strumLine = event.data.strumLine;
    var strumLineIdx = event.data._strumLineIdx;

    for (idx=>seg in segments.segments) seg.control.x = xVal * ((idx % 2 == 0) ? 1 : -1);
}

function splitBezierSegment(segment:BezierSegment, parts:Int) {
    var start = segment.start;
    var control = segment.control;
    var end = segment.end;

    var segments:Array<BezierSegment> = [];

    var totalHeight = end.y - start.y;
    var step = totalHeight / parts;

    for (i in 0...parts) {
        var startY = start.y + step * i;
        var endY = start.y + step * (i + 1);
        var controlY = (startY + endY) / 2;

        var startP = FlxPoint.get(0, startY);
        var controlP = FlxPoint.get(0, controlY);
        var endP = FlxPoint.get(0, endY);

        segments.push(new BezierSegment(startP, controlP, endP));
    }

    return segments;
}
