//a
if (!_useStrumPath) return disableScript();

class BezierSegment {
    public var start:FlxPoint;
    public var control:FlxPoint;
    public var end:FlxPoint;

    public function new(?start:FlxPoint, ?control:FlxPoint, ?end:FlxPoint) {
        this.start = start ?? FlxPoint.get(0, 1);
        this.control = control ?? FlxPoint.get(0, 0);
        this.end = end ?? FlxPoint.get(0, 1);
    }

    public function getPoint(t:Float):FlxPoint {
        var u = 1 - t;
        var x = (u * u) * start.x + 2 * u * t * control.x + (t * t) * end.x;
        var y = (u * u) * start.y + 2 * u * t * control.y + (t * t) * end.y;
        return FlxPoint.get(x, y);
    }
}

import funkin.backend.scripting.events.CancellableEvent;
import openfl.display.BitmapData;
import flixel.util.FlxSpriteUtil;
import openfl.display.StageQuality;
import flixel.tweens.motion.QuadPath;

import flixel.math.FlxPoint;

var __strumDrawnLines = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0x00000000);
function postCreate() {
    for (strumline in strumLines.members) {
        for (strum in strumline.members) strum.extra.set("bezierSegment", new BezierSegment(FlxPoint.get(0, 1), FlxPoint.get(0, 1000*0.5), FlxPoint.get(0, 1000)));
        strumline.onNoteUpdate.add(onNoteUpdate);
    }

    __strumDrawnLines.camera = camHUD;
    insert(members.indexOf(strumLines), __strumDrawnLines);
    __strumDrawnLines.alpha = 0.25;
    __strumDrawnLines.onDraw = (spr) -> {
        if (!__strumDrawnLines.visible || !__strumDrawnLines.active || __strumDrawnLines.alpha <= 0.01) return;
        FlxSpriteUtil.fill(spr, 0x0);
		var old = FlxG.stage.quality;
		FlxG.stage.quality = StageQuality.LOW;

        var whiteLineStyle = FlxSpriteUtil.getDefaultLineStyle({ thickness: 3.5, color: FlxColor.WHITE, });
        var thicknessLineStyle = FlxSpriteUtil.getDefaultLineStyle({ thickness: whiteLineStyle.thickness*3, color: FlxColor.BLACK, });
        FlxSpriteUtil.beginDraw(0x0, whiteLineStyle);
        var _drawing = false;
        for (strumline in strumLines.members) {
            if (!strumline.visible) continue;
            for (strum in strumline.members) {
                if (!strum.extra.exists("bezierSegment")) continue;
                _drawing = true;

                var segment = strum.extra.get("bezierSegment");
                var _x = strum.x + (strum.width*0.5);
                var _y = strum.y + (strum.height*0.5);
                
                var _controlX = segment.control.x + _x;
                var _controlY = segment.control.y + _y;
                
                var _endX = segment.end.x + _x;
                var _endY = segment.end.y + _y;

                for (line in [thicknessLineStyle, whiteLineStyle]) {
                    FlxSpriteUtil.setLineStyle(line);
                    FlxSpriteUtil.flashGfx.moveTo(_x, _y);
                    FlxSpriteUtil.flashGfx.curveTo(_controlX, _controlY, _endX, _endY);

                    // FlxSpriteUtil.flashGfx.moveTo(_x, _y);
                    // FlxSpriteUtil.flashGfx.lineTo(_x, -200);
                }
            }
        }
        if (_drawing) FlxSpriteUtil.endDraw(spr, null);

		FlxG.stage.quality = old;
		spr.draw();
    };
}

// temporarally will only limit to 3 points, ill add more points later
function update(elapsed:Float) {
    for (strumIDX=>strumline in strumLines.members) {
        if (!strumline.visible) continue;
        for (strum in strumline.members) {
            if (!strum.extra.exists("bezierSegment")) strum.extra.set("bezierSegment", new BezierSegment());
            var segment = strum.extra.get("bezierSegment");
            segment.start = FlxPoint.get(0, 1); // dont touch
            segment.control = FlxPoint.get(0, 500);
            segment.end = FlxPoint.get(0, 1000);

            var _event = new CancellableEvent();
            _event.data = {
                segment: segment,
                strum: strum,
                strumLine: strumline,
            };
            PlayState.instance.scripts.event("onStrumPathUpdate", _event);

        }
    }
}

//region Note Update code

function onNoteUpdate(event) {
    var daNote = event.note;
    if (daNote == null) return;
    event.cancelPositionUpdate();
    if (!daNote.exists) return;
    var strum = event.strum ?? daNote.__strum;

    daNote.__strum = strum;
    if (strum.copyStrumCamera) daNote.__strumCameras = strum.lastDrawCameras;
    if (strum.copyStrumScrollX) daNote.scrollFactor.x = strum.scrollFactor.x;
    if (strum.copyStrumScrollY) daNote.scrollFactor.y = strum.scrollFactor.y;
    if (strum.copyStrumAngle && daNote.copyStrumAngle) {
        daNote.__noteAngle = strum.getNotesAngle(daNote);
        daNote.angle = daNote.isSustainNote ? daNote.__noteAngle : strum.angle;
    }
    __updateNotePos(daNote, strum, event);
    for (field in strum.extraCopyFields) CoolUtil.cloneProperty(daNote, field, strum); // TODO: make this cached to reduce the reflection calls - Neo

    if (daNote.isSustainNote) daNote.updateSustain(strum);
}

var __test = new BezierSegment();
function __updateNotePos(daNote, strum, __event) {
    var shouldX = strum.updateNotesPosX && daNote.updateNotesPosX;
    var shouldY = strum.updateNotesPosY && daNote.updateNotesPosY;

    if (!(shouldX || shouldY)) return;

    var time = (daNote.strumTime - Conductor.songPosition) * (0.45 * CoolUtil.quantize(strum.getScrollSpeed(daNote), 100));
    var percent = Math.min(1, Math.max(0, time*0.001));

    if (!strum.extra.exists("bezierSegment")) strum.extra.set("bezierSegment", new BezierSegment());
    var segment = strum.extra.get("bezierSegment");

    var currentPoint = segment.getPoint(percent);

    if (shouldX) {
        if (percent != 0) daNote.x = currentPoint.x + (strum.width - daNote.width) * 0.5;
        else daNote.x = (strum.width - daNote.width) * 0.5;
    }

    if (shouldY) {
        if (percent != 0) daNote.y = currentPoint.y;
        else daNote.y = time * (0.45 * CoolUtil.quantize(strum.getScrollSpeed(daNote), 100));
        if (daNote.isSustainNote) daNote.y += strum.N_WIDTHDIV2;
    }
}

//endregion