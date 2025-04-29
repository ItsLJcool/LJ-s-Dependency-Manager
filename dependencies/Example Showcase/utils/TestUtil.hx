//a

public function testFunction() { trace("testFunction was called!"); }

var alreadyHasDebug:Bool = false;
var __debugSprite:FlxSprite = null;
public function debugShowcase() {
    if (alreadyHasDebug) return;
    alreadyHasDebug = true;

    trace("debugShowcase was called!");

    __debugSprite = new FlxSprite().makeSolid(200, 200, 0xFFFF0000);
    __debugSprite.screenCenter();
    __debugSprite.scrollFactor.set();
    add(__debugSprite);
}

var __time:Float = 0;

function update(elapsed:Float) {
    __time += elapsed;
    if (alreadyHasDebug && __debugSprite != null) __debugSprite.x = ((FlxG.width - __debugSprite.width) * 0.5) + Math.sin((__time) * 4) * 20;
}