## Strumline Path Dependency

This dependency makes it possible to change the note's path, and it adds a path that shows the note's line and how it gets to the Strum.

Similar to NotITG's `strum arrow line`.

~~Currently it only has 3 points but I plan on making it possible to add infinite points to truly customize the path.~~

It has been updated to support multiple points, using the `BezierSegment` class.
You can import both classes by doing:
```haxe
import BezierSegment;
import BezierSegments;
```

### Usage
Here are some examples of how to use / edit the points:
```haxe
function onStrumPathUpdate(event) {
    var segments = event.data.segments;

    var firstSegment = segments.segments[0];

    firstSegment.control.x = Math.sin((Conductor.songPosition*0.001)*4)*150;
}
```
This will make it so the path will sway left and right.

currently the only things in the event are:
- `segments`: A `BezierSegments` class, which contains the segments of the custom path.
- `strum`: the strum that is being updated.
- `strumLine`: the strum line that is being updated.
- `_arrowlinesSprite`: The entire sprite that renders the paths. It's all drawn on 1 sprite.

You access these with the `data` field, as I havent made a custom class the cancellable event to add custom variables yet. But cancelling the event does nothing currently.

If you want to reset the path back to normal, the first point set it to `0, 1` and the control point is half of the y value of the end point, which is `0, 1000`, so the control point is `0, 500`.

```haxe
segment.start = FlxPoint.get(0, 1);
segment.control = FlxPoint.get(0, 500);
segment.end = FlxPoint.get(0, 1000);
```

The control point will slow or speed up notes, as its using a besier curve. The scrollSpeed still changes the note's speed, but you can use the control point to mess around with the speed.

Each strum now has some custom fields in `extra` that allow you to edit how the path handles it.
for example:
```haxe
strum.extra.set("segments_speedMult", 0.5);
```
This will make the path speed only 0.5 times faster than normal.

You can also toggle the arrow's visibility with:
```haxe
strum.extra.set("draw_arrowline", false);
```

You can't edit the alpha of the arrowline, because all the arrow lines are drawn to 1 single sprite, that renders all of them. This boolean just tells the sprite if it should draw that strum or not.