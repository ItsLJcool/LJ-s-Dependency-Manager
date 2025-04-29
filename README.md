# LJ's Dependency Manager
This is for your own Codename Engine Mod, and in a short sense, it's basically is a modding system inside your mod.

Now, it's not a "Modding System" per se, but all the Dependency Manager does is load the folders in the `dependencies` folder exactly like a CodenameEngine Mod.

This has benifits, like being able to offload code to the folder, and being able to path find it as well.

From what I can tell, it basically just acts like if you moved the folder into your mod's folder.

### Why would I want to use this?
Well, you know how addons work? Well think of this as a local Addons system. You can format it any way you want, but here are some examples of use cases:

1. You want to reuse really complicated code but don't feel like copy / pasting code, mashing it into your mod.
    - Instead of just want to reuse code, simpily just drag and drop a folder, and you can instantly call functions and store data within it!
2. You want to organize your mod, so that some things like Extra Content or "DLC" can be loaded alongside your Main Mod.
    - It works exactly like you'd expect, but the only issue would be that saving anyting from CNE, will direct the save file to the Main Mod's folder, so keep that in mind!
3. You just want to make a Custom Modding System for your own mod.
    - With this, its basically possible, but isn't coded for this. You would have to make your own system manually.


## Pro's and Con's

### Pro's
- Easy to use, as it's basically like a Mod Folder but allows you to reference files from the Main Mod's folder.
- Useful for abstracting code, so you can reuse it anywhere.
- Can be used in many different ways, examples as: DLC, Abstracting Code, etc.

### Con's
- If you are planning on using it as a DLC loader, anything that CodenameEngine saves will be saved to the Main Mod's root folder, so instead of `./dependencies/your-dependency/songs/Song-Name/charts/hard.json` it will save to `./songs/Song-Name/charts/hard.json`.
- Since we load the mod manually, It will be in the **top** of the AssetLibrary. This means that CodenameEngine will load those scripts before the Main Mod's scripts.<br>
**Example:** Loading a Song, means it will load all the scripts in `./dependencies/songs/`, before loading `./songs/`.

# How to use
All you do is make a folder in the `dependencies` folder, and that's it!
You can have the Dependency be named something specific, and all you do is make a file called `.enabled` in the folder, and put the name of the dependency in it.

You can name it `.enabled` or `.disabled`, and it does what you think it does. It disables or enables the dependency.

The folder works exactly like a Mod Folder, and you can even add custom songs, characters, etc. if you want to.

### Some Special features
There is a slight problem though.<br>
Let's say you want a dependency to edit a State Script, it will load normally, but function's you make in the Main Mod's State Script, will not be called in the Dependency's State Script.

I basically made Unity's Harmony Patch when you load the Dependency Manager. (Crimson, a friend said it works similarly lol).

It's not meant to work exactly like it, but in a short sense it basically does.

What this allows you to do, is to make a comment above a function with a specific format, and it will rebound the function so that all Dependencies get called as well.

To allow dependencies to call / recieve functions, you add a comment above the function with the prefix `//#depend`.

You can specify parameters with the Pipe (`|`) but as of this README Update, there is only one parameter: `globalFunction`.

Here is an example:
```haxe
// Main Mod's State Script

//#depend|globalFunction
function someFunction(number:Int) {
    trace("Im running a function! Your number is: " + number);
}
```
```haxe
// Dependency's State Script

function pre_someFunction(number:Int) {
    trace("Hey! Your number is: " + number + "!!!");
}
```
When you run the function in either script, both functions will run.

You can only get the `pre_` and `post_`, it will only call the function with the prefix.

### Overriding Return Values
You can also override what the function returns normally.

If you return a value in the function, it will override the normal return value. This only works in the `post_` function.

Here is an example:
```haxe
// Main Mod's State Script

//#depend|globalFunction
function randomInt(min:Int, max:Int) {
    return FlxG.random.int(min, max);
}
```
```haxe
// Dependency's State Script

function post_randomInt(min:Int, max:Int) {
    return FlxG.random.int(min, max) * 4;
}
```
```haxe
// Result when running anywhere
trace(randomInt(1, 4)); // possible return values: [4, 8, 12, 16]
```