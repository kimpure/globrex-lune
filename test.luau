local globrex = require('./init');

local result = globrex('p*uck')

print(result.regex:test('pluck')); -- true