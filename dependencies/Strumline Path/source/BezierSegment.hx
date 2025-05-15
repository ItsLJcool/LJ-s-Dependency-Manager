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
