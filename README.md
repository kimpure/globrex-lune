# globrex-lune

<div align="center">
    glob to regular expression compiler.
</div>

## Note
This library is the lune version of <a href="https://github.com/terkelg/globrex">globrex</a> <br>
use module : <a href="https://github.com/Roblox/luau-regexp">luau-regexp</a>

## Install
```bash
git submodule add https://github.com/kimpure/globrex-lune.git globrex-lune
```

## Example
```luau
local globrex = require('globrex-lune');

local result = globrex("**/*.luau", { globstar = true })

print(result)
print(result.regex)
print(result.path)
```
## Description

module import
```luau
local globrex = require('globrex-lune');
```

get Result
```luau
local result = globrex(glob: string, option: {
    extended: boolean?, 
    globstar: boolean?, 
    strict: boolean?, 
    filepath: boolean?, 
    flags: string?
}?)
```
