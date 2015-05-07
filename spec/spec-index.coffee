
assert = require 'assert'
bson = require 'bson'
$ = require '../src'

describe 'diff', ->

  it 'should produce no difference', ->
    assert.equal false, $.diff [], []
    assert.equal false, $.diff [1], [1]
    assert.equal false, $.diff [1, 2, 3], [1, 2, 3]
    assert.equal false, $.diff {}, {}
    assert.equal false, $.diff {foo:bar:1}, {foo:bar:1}
    assert.equal false, $.diff {foo:1}, {foo:1}
    assert.equal false, $.diff {foo:1}, {foo:1}, 'my.scope', inc: true

  it 'should produce simple diffs', ->
    assert.deepEqual { '$set': { '0': 2, '1': 1 } }, $.diff [1, 2], [2, 1]
    assert.deepEqual { '$inc': { '0': 1, '1': -1 } }, $.diff [1, 2], [2, 1], null, inc: true
    assert.deepEqual { '$set': { bar: 1, foo: 2 } }, $.diff {foo:1,bar:2}, {bar:1,foo:2}
    assert.deepEqual { '$rename': { foo: 'bar' } }, $.diff {foo:1}, {bar:1}

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

    assert.deepEqual r, $.diff a, b, ['my', 'value']

  it 'should work with dates', ->
    a = new Date 1417434298178
    a2 = new Date 1417434298178
    b = new Date 1417434298179
    assert.equal false, $.diff { foo: a }, { foo: a2 }
    assert.deepEqual { $set: { foo: b } }, $.diff { foo: a }, { foo: b }

  it 'should work with regexps', ->
    a = /foo/
    a2 = /foo/
    b = /foo/g
    assert.equal false, $.diff { foo: a }, { foo: a2 }
    assert.deepEqual { $set: { foo: b } }, $.diff { foo: a }, { foo: b }

  it 'should work with nulls', ->
    a = new Date
    assert.deepEqual { $set: { foo: null } }, $.diff { foo: 1 }, { foo: null }
    assert.deepEqual { $set: { foo: null } }, $.diff { foo: a }, { foo: null }
    assert.deepEqual { $set: { foo: 1 } }, $.diff { foo: null }, { foo: 1 }
    assert.deepEqual { $set: { foo: a } }, $.diff { foo: null }, { foo: a }

  # it 'should remove array elements', ->
  #   assert.deepEqual {foo:[1,2,3,5]}, $.apply {foo:[1,2,3,5,7]}, {$rename:{'foo.4':'foo.3'}}
  #   assert.deepEqual {foo:[1,2,5,7]}, $.apply {foo:[1,2,3,5,7]}, {$unset:{'foo.2':true}}

  it 'should rename nested objects', ->
    assert.deepEqual { $rename: { foo: 'bar' } }, $.diff { foo: { a: 1, b: 2 } }, { bar: { a: 1, b: 2 } }
    assert.deepEqual { $rename: { foo: 'bar', foo2: 'bar2' } }, $.diff { foo: {a:1}, foo2: {a:2} }, { bar: {a:1}, bar2: {a:2} }

  it 'should apply diff correctly on cloned objects', ->

    f = (a, b) ->
      d = $.diff a, b
      assert.equal false, $.diff $.apply($.clone(a), d), b

    f {foo:1}, {foo:1}
    f {foo:1}, {foo:2}
    f {foo:1}, {foo:'x'}
    f {foo:1}, {bar:1}
    f {foo:{bar:'z'}}, {bar:1}
    f {foo:{bar:'z'}}, {foo:{foo:'z'}}

  it 'should apply $inc to non-existing nested value', ->
    assert.deepEqual { "foo": { "bar": 1 } }, $.apply({}, { "$inc": { "foo.bar": 1 } })

  it 'should resolve with forced creation of containers', ->
    a = {foo:1}
    assert.deepEqual [{}, ['one']], $.resolve a, 'bar.force.one', force: true
    assert.deepEqual {foo:1,bar:{force:{}}}, a
    assert.deepEqual [{force:{}}, ['force2', 'one2']], $.resolve a, 'bar.force2.one2', force: false
    assert.deepEqual [{}, ['name']], $.resolve a, ['alist', 0, 'insidelist', 0, 'name'], force: true
    assert.deepEqual {foo:1,bar:{force:{}},alist:[{insidelist:[{}]}]}, a
    assert.deepEqual [[], [0]], $.resolve a, ['alist2', 0], force: true
    assert.deepEqual {foo:1,bar:{force:{}},alist:[{insidelist:[{}]}],alist2:[]}, a

  it 'should arrize', ->
    assert.deepEqual [], $.arrize []
    assert.deepEqual [], $.arrize ['']
    assert.deepEqual [], $.arrize [null]
    assert.deepEqual [], $.arrize [false]
    assert.deepEqual [], $.arrize [undefined]
    assert.deepEqual [], $.arrize()
    assert.deepEqual [], $.arrize ''
    assert.deepEqual [], $.arrize null
    assert.deepEqual [], $.arrize false
    assert.deepEqual [], $.arrize undefined

  it 'should resolve empty keypath', ->
    assert.deepEqual [{foo:1}, []], $.resolve {foo:1}, ['']
    assert.deepEqual [{foo:1}, []], $.resolve {foo:1}, [null]
    assert.deepEqual [{foo:1}, []], $.resolve {foo:1}, [false]
    assert.deepEqual [{foo:1}, []], $.resolve {foo:1}, [undefined]
    assert.deepEqual [{foo:1}, []], $.resolve {foo:1}, []
    assert.deepEqual [{foo:1}, []], $.resolve {foo:1}, ''
    assert.deepEqual [{foo:1}, []], $.resolve {foo:1}, null
    assert.deepEqual [{foo:1}, []], $.resolve {foo:1}, false
    assert.deepEqual [{foo:1}, []], $.resolve {foo:1}, undefined

  it 'should work with undefined', ->
    assert.deepEqual $.diff({ foo: null }, { foo: undefined }), { $set: { foo: undefined } }

  it 'should work with bson types', ->
    a = new bson.ObjectId
    b = new bson.ObjectId
    assert.deepEqual $.diff({foo:a}, {foo:b}), { $set: { foo: b } }

    a = new bson.ObjectId '5516058702c536d6068cabb7'
    b = new bson.ObjectId '5516058702c536d6068cabb7'
    assert.equal $.diff({foo:a}, {foo:b}), false

  # describe 'others', ->
  #
  #   it 'should work with BSON ObjectId', ->
  #     { ObjectId } = require 'bson/lib/bson/objectid'
  #     d = {
  #       _id: ObjectId()
  #       foo: 'FOO'
  #       bar: undefined
  #     }
  #     console.log $.diff d, {}

  describe 'isRealNumber', ->

    it 'should work with real numbers', ->
      assert.equal true, $.isRealNumber 0
      assert.equal true, $.isRealNumber 0, 1.1

    it 'should catch NaN', ->
      assert.equal false, $.isRealNumber 0, NaN

    it 'should catch +/-Infinity', ->
      assert.equal false, $.isRealNumber Infinity
      assert.equal false, $.isRealNumber -Infinity
      assert.equal false, $.isRealNumber 1, Infinity
      assert.equal false, $.isRealNumber -Infinity, 1
