
assert = require 'assert'
$ = require '../src'

y = (a, b) ->
  assert.deepEqual a, b

describe 'diff', ->

  it 'should produce no difference', ->
    y false, $.diff [], []
    y false, $.diff [1], [1]
    y false, $.diff [1, 2, 3], [1, 2, 3]
    y false, $.diff {}, {}
    y false, $.diff {foo:bar:1}, {foo:bar:1}
    y false, $.diff {foo:1}, {foo:1}
    y false, $.diff {foo:1}, {foo:1}, 'my.scope', inc: true
    y false, $.diff {foo:undefined}, {foo:undefined}

  it 'should produce diff with undefined', ->
    y { $set: { foo: undefined } }, $.diff { foo: 1 }, { foo: undefined }
