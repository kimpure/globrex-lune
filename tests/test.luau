local globrex = require('..');

local result = globrex('p*uck')

print(result.regex.source)
print(result.regex:test('pluck')); -- true