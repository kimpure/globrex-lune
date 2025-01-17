local regex = require('@lune/regex')
local regexp = require('../luau_packages/luau_regexp')

export type RegExpImpl = {
    __index: RegExpImpl,
    test: (self: RegExp, text: string) -> (boolean),
    exec: (self: RegExp, text: string) -> {
        [number]: string,
        index: number,
        input: string,
    }?,
    
}

export type RegExp = typeof(setmetatable({} :: {
    source: string,
    regex: regex.Regex,
}, {} :: RegExpImpl))

local regex_support = {} :: RegExpImpl
regex_support.__index = regex_support

function new(pattern: string, option: any): RegExp
    local source = (regexp.new(pattern, option) :: any).source
    local regex =  regex.new(source)
    return setmetatable({
        source = source,
        regex = regex,
    }, regex_support)
end

function regex_support.test(self, text)
    return self.regex:isMatch(text)
end

function regex_support.exec(self, text)
    local regex = self.regex
    local captures = regex:captures(text)
    
    if not captures then
        return nil
    end
    
    local result = {}
    local index = 0

    while true do
        if not captures:get(index) then
            break
        end
        result[index] = (captures:get(index) :: any).text
        index += 1
    end
    
    result.index = (captures:get(0) :: any).start
    result.input = text

    return result
end


return new