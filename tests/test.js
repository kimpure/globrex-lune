const js = new RegExp('^((?:[^/]*(?:/|$))*)([^/]*)\.js$');

console.log(js.exec('w.js'));
console.log(js.test('w.js'));