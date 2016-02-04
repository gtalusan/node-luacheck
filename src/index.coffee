argparse = require "./argparse"
LuacheckError = require "./Error"

subprocess = require "child_process"
fs = require "fs"
path = require "path"


luacheck = (filename, options={}, cb=null) ->
    if typeof options is "function"
        cb = options
        options = {}
    if typeof filename isnt "string"
        throw new Error("Please pass in a filename")
    if not fs.existsSync(filename)
        throw new Error("'#{filename}' does not exist")

    luacheck.errors = []

    # figure out what to run
    exec = "luacheck"
    if options.exec
        exec = path.resolve(options.exec, exec)
    if process.platform is "win32"
        exec += ".bat"

    # figure out where to run it from
    if options.cwd
        cwd = options.cwd
    else
        cwd = path.dirname(filename)

    args = [
        path.resolve('.', filename),
        "--quiet",
        "--codes",
        "--no-color",
        "--formatter", "plain"
    ].concat(argparse(options))


    child = subprocess.spawn(exec, args, "cwd": cwd, "encoding": "utf-8")
    regexp = /^(.+)\:(\d+)\:(\d+)\:\s*\((W\d+)\)\s*(.+)$/

    stdout = ""
    child.stdout.on('data', (data) =>
        stdout += data;
    )
    child.on('close', (code) =>
        for line in stdout.split(/\r?\n/)
            match = regexp.exec(line)
            if match
                luacheck.errors.push(new LuacheckError(match))
        if cb
            cb(null, luacheck.errors)
    )


module.exports = luacheck
