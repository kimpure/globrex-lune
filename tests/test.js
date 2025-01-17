const foobar = new RegExp('^((?:[^/]*(?:/|$))*)foo(bar|b([^/]*)z)$');

console.log(foobar.exec('foobuzz'));
console.log(foobar.test('foobuzz'));
