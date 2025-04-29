// Credits to ItsLJcool for the Mod Dependencies idea, and code for it. Thanks to Neo for helping a bit for figuring out how it works properly.

import funkin.backend.system.Logs;

import funkin.backend.scripting.Script;
import funkin.backend.scripting.DummyScript;

import funkin.backend.assets.ModsFolder;

import funkin.backend.scripting.GlobalScript;

import funkin.backend.MusicBeatState;
import funkin.backend.MusicBeatSubstate;

import haxe.io.Path;

// this just sits here looking pretty, but I'd put this in your Main mod's GlobalScript, so it can access this function if you disable the Dependency's `global.hx` script.
static var _dependsLoaded:Array<{folderName:String, dlcName:String}> = [];

var __disableLogging:Bool = false;

// If disabled, Dependencies will not load the `global.hx` script in `data/global.hx`.
var allowGlobalScript:Bool = true;

var folderPath = "dependencies";

//region Initalizing dependencies
function new() {
    _log([Logs.logText("Initalizing dependencies...", -1)]);

    var _modDependencies = Paths.getFolderDirectories(folderPath);
    if (_modDependencies.length <= 0) return _log([Logs.logText("No mod dependencies found.", -1)], 1);
    
    for (directory in _modDependencies) {
        var path = folderPath + "/" + directory;
        
        var disabledFile = Paths.getPath(path + "/.disabled");
        if (Assets.exists(disabledFile)) continue;
        try {
            Paths.assetsTree.addLibrary(ModsFolder.loadModLib(ModsFolder.modsPath+ModsFolder.currentModFolder+"/"+path, false, directory));

            // now we call this to import all the scripts that are in the dependency folder, it will load the ones that aren't loaded yet
            if (allowGlobalScript) GlobalScript.scripts.importScript("data/global.hx");

            _log([
                Logs.logText("Loaded ", -1),
                Logs.logText(directory, 6),
                Logs.logText(" dependency.", -1),
            ]);
            
            var dependencyName = Paths.getPath(path + "/.enabled");
            if (!Assets.exists(dependencyName)) dependencyName = StringTools.trim(directory); // backup ig
            else dependencyName = StringTools.trim(Assets.getText(dependencyName));
            _dependsLoaded.push({
                dlcName: dependencyName,
                folderName: directory,
            });
        } catch (e:Error) {
            _log([
                Logs.logText("Failed to load ", -1),
                Logs.logText(directory, 6),
                Logs.logText(" dependency. Error: ", -1),
                Logs.logText(e, -1),
            ], 2);
        }
    }
}

//endregion

function _log(?logText:Array, ?type:Int) {
    if (__disableLogging) return;
    
    logText ??= [];
    if (logText.length == 0) return;
    type ??= 0;
    logText.insert(0, Logs.logText("[LJ Mod Dependencies] ", 10));
    Logs.traceColored(logText, type);
}

//region Harmony Patch in HScript. les go!!!

import Lambda;
// in case of oversight, add code to reference the ScriptPack that the state offers.
var possible_scriptRemap:Map<FlxState, Dynamic->Dynamic> = [
    MusicBeatState => (script) -> {
        return (script.interp.scriptObject is MusicBeatSubstate) ? FlxG.state.subState.stateScripts : FlxG.state.stateScripts;
    },
];

function onScriptSetup(script:Script, type:String) {
    type ??= "hscript";
    if (type != "hscript" || script == null || script.code == null) return;

    // return; // comment out to disable Dependencies being allowed to override functions.
    
    var stateScripts = null;
    for (data in possible_scriptRemap.keys()) {
        if (!(FlxG.state is data)) continue;
        var func = possible_scriptRemap.get(data);
        stateScripts = func(script);
        break;
    }
    
    if (stateScripts == null) return;

    var codeLines = script.code.split("\n");
    var lambdaHasLine = Lambda.exists(codeLines, line -> StringTools.startsWith(StringTools.trim(line), "//#"));
    if (!lambdaHasLine) return;

    for (idx=>line in codeLines) {
        var nextLine = StringTools.trim(codeLines[idx+1]);
        if (nextLine == null) continue;
        line = StringTools.trim(line);
        if (!StringTools.startsWith(line, "//#")) continue;

        line = line.substr(3);
        var items = line.split("|");
        if (items.shift() != "depend") continue;

        for (dlc in items) harmonyPatch(script, dlc, nextLine, stateScripts);
        
    }
}

// This basically allows you to override functionality of the code in the Main mod, and the Dependency can override calls to it if you allow it.
// it was designed in Pillar Funkin' for "DLC" mods to be able to override the main mod's code, but you can add whatever you want I guess.
function harmonyPatch(script:Script, data:String, nextLine:String, globalScripts) {
    switch(data) {
        case "globalFunction":
            var funcWhole = "";
            // idx == 1 means its not a public variable, but if its not 1 then the function is formated like `something function()` or `something another function()`
            // so we check for the public variables for the function, but never change the static functions since it can be accessed anywhere anyways.
            var idx = 1; 
            while (true) {
                funcWhole = getWord(nextLine, idx);
                if (StringTools.contains(funcWhole, "(")) break;
                idx++;
            }
            
            var funcName = cutAfterLetter(funcWhole, "(", false);
            var funcObj = (idx == 1) ? script.get(funcName) : script.interp.publicVariables.get(funcName);
            if (!Reflect.isFunction(funcObj)) return;
            
            var _globalFunc = (prefix:String, arguments) -> {
                var __return = null;
                for (_scr in globalScripts.scripts) {
                    if (_scr == script) continue;
                    var overrideReturn = _scr.call(prefix+funcName, arguments);
                    if (overrideReturn != null) __return = overrideReturn;
                }
                return __return;
            }

            var replacingFunction = Reflect.makeVarArgs((arguments) -> {
                var __return = null;
                _globalFunc("pre_", arguments);

                __return = Reflect.callMethod(null, funcObj, arguments); // orginal function

                var overrideReturn = _globalFunc("post_", arguments);
                return (overrideReturn != null) ? overrideReturn : __return;
            });

            for (_scr in globalScripts.scripts) {
                if (_scr == script) {
                    if (idx == 1) _scr.set(funcName, replacingFunction);
                    else _scr.interp.publicVariables.set(funcName, replacingFunction);
                    continue;
                }
                _scr.set(funcName, replacingFunction);
            }

    }
}
//endregion

import EReg;
function getWord(line:String, index:Int) {
    var regex = new EReg("\\s+", "g"); 
    var words = regex.split(line);
    return (index >= 0 && index < words.length) ? words[index] : "";
}

function cutAfterLetter(line:String, letter:String, ?includeLetter:Bool = false) {
    includeLetter ??= false;
    var idx = line.indexOf(letter);
    if (idx == -1) return line;
    return includeLetter ? line.substr(0, idx + 1) : line.substr(0, idx);
}
