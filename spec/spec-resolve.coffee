
assert = require 'assert'
$ = require '../src'

y = (a, b) ->
  assert.deepEqual a, b

describe 'resolve', ->

  it 'should not throw', ->
    y [ null, [ 'foo', 'bar' ] ], $.resolve null, 'foo.bar'

  it 'should resolve', ->
    y [ { bar: 'baz' }, [ 'bar' ] ], $.resolve { foo: bar: 'baz' }, 'foo.bar'
