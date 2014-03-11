assert = require 'assert'
{rusDiff} = require '../src'

describe 'rusDiff', ->
  it 'should produce no difference', ->
    assert.equal false, rusDiff [], []
    assert.equal false, rusDiff [1], [1]
    assert.equal false, rusDiff [1, 2, 3], [1, 2, 3]
    assert.equal false, rusDiff {}, {}
    assert.equal false, rusDiff {foo:bar:1}, {foo:bar:1}
    assert.equal false, rusDiff {foo:1}, {foo:1}

  it 'should produce simple diffs', ->
    assert.deepEqual { '$set': { '0': 2, '1': 1 } }, rusDiff [1, 2], [2, 1]
    assert.deepEqual { '$set': { bar: 1, foo: 2 } }, rusDiff {foo:1,bar:2}, {bar:1,foo:2}
    assert.deepEqual { '$rename': { foo: 'bar' } }, rusDiff {foo:1}, {bar:1}

  it 'should produce scoped diff', ->
    a =
      foo:
        bb:
          inner:
            this_is_a: 1
            to_rename: "Hello"
        aa: 1
      bar: 1
      replace_me: 1

    b =
      foo:
        bb:
          inner:
            this_is_b: 2
        cc:
          new_val: 2
      bar2: 2
      zz: 2
      renamed: "Hello"
      replace_me: 2

    r =
      $rename:
        "my.value.foo.bb.inner.to_rename": "my.value.renamed"
      $unset:
        "my.value.bar": true
        "my.value.foo.aa": true
        "my.value.foo.bb.inner.this_is_a": true
      $set:
        "my.value.bar2": 2
        "my.value.foo.bb.inner.this_is_b": 2
        "my.value.foo.cc":
          new_val: 2
        "my.value.replace_me": 2
        "my.value.zz": 2

    assert.deepEqual r, rusDiff a, b, ['my', 'value']