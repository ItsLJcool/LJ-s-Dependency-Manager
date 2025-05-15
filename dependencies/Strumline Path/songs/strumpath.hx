//a

if (!_useStrumPath) return disableScript();

import BezierSegment;
import BezierSegments;

import funkin.backend.scripting.events.CancellableEvent;
import openfl.display.BitmapData;
import flixel.util.FlxSpriteUtil;
import openfl.display.StageQuality;
import flixel.tweens.motion.QuadPath;

import flixel.math.FlxPoint;

var __strumDrawnLines = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0x00000000);
function postCreate() {
    for (strumline in strumLines.members) {
        for (strumIdx=>strum in strumline.members) {
            strum.extra.set("bezierSegments", new BezierSegments([new BezierSegment(FlxPoint.get(0, 1), FlxPoint.get(0, 500), FlxPoint.get(0, 1000))]));
            strum.extra.set("segments_speedMult", 1);
            strum.extra.set("draw_arrowline", true);
            PlayState.instance.scripts.call("onStrumPathGenerated", [strum]);
        }
        strumline.onNoteUpdate.add(onNoteUpdate);
    }

    __strumDrawnLines.camera = camHUD;
    insert(members.indexOf(strumLines), __strumDrawnLines);
    __strumDrawnLines.alpha = 0;
    if (__strumsDoAnimation) FlxTween.tween(__strumDrawnLines, {alpha: 0.25}, Conductor.crochet*0.001, {ease: FlxEase.circOut, startDelay: (Conductor.crochet * 0.001)*3});
    else __strumDrawnLines.alpha = 0.25;
    __strumDrawnLines.onDraw = (spr) -> {
        if (!__strumDrawnLines.visible || !__strumDrawnLines.active || __strumDrawnLines.alpha <= 0.01) return;
        FlxSpriteUtil.fill(spr, 0x0);
		var old = FlxG.stage.quality;
		FlxG.stage.quality = StageQuality.LOW;

        var whiteLineStyle = FlxSpriteUtil.getDefaultLineStyle({ thickness: 3.5, color: FlxColor.WHITE, });
        var thicknessLineStyle = FlxSpriteUtil.getDefaultLineStyle({ thickness: whiteLineStyle.thickness*3, color: FlxColor.BLACK, });
        FlxSpriteUtil.beginDraw(0x0, whiteLineStyle);

        var _drawing = false;
        for (_tempIdx=>strumline in strumLines.members) {
            if (!strumline.visible) continue;
            for (strum in strumline.members) {
                if (!strum.extra.exists("bezierSegments")) continue;
                if (strum.extra.exists("draw_arrowline") && !strum.extra.get("draw_arrowline")) continue;
                _drawing = true;

                var segments = strum.extra.get("bezierSegments");
                for (segment in segments.segments) {
                    var _x = strum.x + (strum.width*0.5);
                    var _y = strum.y + (strum.height*0.5);

                    var _startX = segment.start.x + _x;
                    var _startY = segment.start.y + _y;
                    
                    var _controlX = segment.control.x + _x;
                    var _controlY = segment.control.y + _y;
                    
                    var _endX = segment.end.x + _x;
                    var _endY = segment.end.y + _y;

                    for (line in [thicknessLineStyle, whiteLineStyle]) {
                        FlxSpriteUtil.setLineStyle(line);
                        FlxSpriteUtil.flashGfx.moveTo(_startX, _startY);
                        FlxSpriteUtil.flashGfx.curveTo(_controlX, _controlY, _endX, _endY);

                        // FlxSpriteUtil.flashGfx.moveTo(_x, _y);
                        // FlxSpriteUtil.flashGfx.lineTo(_x, -200);
                    }
                }
            }
        }
        if (_drawing) FlxSpriteUtil.endDraw(spr, null);

		FlxG.stage.quality = old;
		spr.draw();
    };
}

var __strumsDoAnimation = false;
function onStrumCreation(event) {
    __strumsDoAnimation = event.__doAnimation;
}

// temporarally will only limit to 3 points, ill add more points later
function update(elapsed:Float) {
    for (strumlineIdx=>strumline in strumLines.members) {
        if (!strumline.visible) continue;
        for (strumIdx=>strum in strumline.members) {
            if (!strum.extra.exists("bezierSegments")) continue;

            var segments = strum.extra.get("bezierSegments");
            var _event = new CancellableEvent();
            _event.data = {
                segments: segments,
                strum: strum,
                _strumIdx: strumIdx,

                strumLine: strumline,
                _strumLineIdx: strumlineIdx,

                _arrowlinesSprite: __strumDrawnLines,
            };

            PlayState.instance.scripts.event("onStrumPathUpdate", _event);
        }
    }
}

//region Note Update code

function onNoteUpdate(event) {
    var daNote = event.note;
    if (daNote == null || !daNote.exists) return;

    var strum = event.strum ?? daNote.__strum;

    if (!strum.extra.exists("bezierSegments")) return;
    event.cancelPositionUpdate();

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

    if (daNote.isSustainNote) {
        daNote.updateSustain(strum);
    }
}

var __test = new BezierSegment();
function __updateNotePos(daNote, strum, __event) {
    var shouldX = strum.updateNotesPosX && daNote.updateNotesPosX;
    var shouldY = strum.updateNotesPosY && daNote.updateNotesPosY;

    if (!(shouldX || shouldY)) return;
    var segments = strum.extra.get("bezierSegments");
    var speedMult = (strum.extra.exists("segments_speedMult")) ? strum.extra.get("segments_speedMult") : 1;

    var time = (daNote.strumTime - Conductor.songPosition);
    time *= speedMult;
    var scrollTime = time * (0.45 * CoolUtil.quantize(strum.getScrollSpeed(daNote), 100));

    segments.percent = Math.max(0, time*0.001);
    
    var currentPoint = segments.getPoint();

    if (shouldX) {
        if (segments.percent != 0) daNote.x = currentPoint.x + (strum.width - daNote.width) * 0.5;
        else daNote.x = (strum.width - daNote.width) * 0.5;
    }

    if (shouldY) {
        if (segments.percent != 0) daNote.y = currentPoint.y;
        else daNote.y = scrollTime * (0.45 * CoolUtil.quantize(strum.getScrollSpeed(daNote), 100));
        if (daNote.isSustainNote) daNote.y += strum.N_WIDTHDIV2;
    }
}

//endregion