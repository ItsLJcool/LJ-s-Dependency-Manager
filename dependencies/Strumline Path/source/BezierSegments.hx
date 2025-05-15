class BezierSegments {

    public var percent:Float = 0;

    public var segments:Array<BezierSegment> = [];

    public function new(segments:Array<BezierSegment>) {
        this.segments = segments;
    }

    public function addSegment(segment:BezierSegment) segments.insert(0, segment);
    public function insertSegment(segment:BezierSegment, index:Int) segments.insert(index, segment);
    
    public function getSegment(index:Int) return segments[index];

    public function getPoint():FlxPoint {
        var _localSegments = segments.copy();
        _localSegments.reverse();
        var segmentCount = _localSegments.length;
        if (segmentCount == 0) return FlxPoint.get(0, 0);

        var totalT = FlxMath.bound(this.percent, 0, 1); // Clamp just in case

        // Dynamically calculate index
        var i = Math.floor(totalT * segmentCount);
        i = Std.int(FlxMath.bound(i, 0, segmentCount - 1));

        var segmentStart = i / segmentCount;
        var localT = (totalT - segmentStart) * segmentCount;
        localT = FlxMath.bound(localT, 0, 1);

        return _localSegments[i].getPoint(localT);
    }
}