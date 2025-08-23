local glob = require('../src/lib')

local foobar = glob('**/foo{bar,b*z}', { globstar = true, extended = true }).regex

print(foobar.source)
print(foobar:exec('foobuzz'))
print(foobar:test('foobuzz'))
