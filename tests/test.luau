local glob = require('../src')

local js = glob('**/*.js', { globstar = true }).regex

print(js.source)
print(js:exec('w.js'))
print(js:test('w.js'))


