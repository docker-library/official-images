class Container {
    static function main():Void {
        switch (Sys.command("haxelib", ["newrepo"])) {
            case 0: //pass
            case code: Sys.exit(code);
        }
        switch (Sys.command("haxelib", ["install", "jQueryExtern"])) {
            case 0: //pass
            case code: Sys.exit(code);
        }
    }
}
