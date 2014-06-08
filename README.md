## Summary

(R)emove-(U)pdate-(S)et JSON diff library can be used standalone to compute difference between two JSON objects.

Produced diff is MongoDB compatible and can be used to modify documents with `collection.update(...)`.

## Examples

| a | b | diff(a, b) | options |
|---|---|------------|---------|
| `{ "foo": 1 }` | `{ "bar": 1 }` | `{ '$rename': { foo: 'bar' } }` | |
| `{ "foo": 1 }` | `{ "bar": 2 }` | `{ "$unset": { foo: true }, "$set": { bar: 2 } }` | |
| `{ "foo": 1 }` | `{}` | `{ '$unset': { foo: true } }` | |
| `{ "foo": 1 }` | `{ "foo": 2.5 }` | `{ '$set': { foo: 2.5 } }` | |
| `{ "foo": 1 }` | `{ "foo": 2.5 }` | `{ '$inc': { foo: 1.5 } }` | `{ "inc": true }` |

| a | diff | apply(a, diff) |
|---|---|-------------|
| `{}` | `{ "$inc": { "foo.bar": 1 } }` | `{ foo: { bar: 1 } }` |
| `{ "foo": 1.5 }` | `{ "$inc": { "foo": -2.5 } }` | `{ foo: -1 }` |
| `{ "foo": true }` | `{ "$rename": { "foo": "bar" } }` | `{ bar: true }` |
| `{ "foo": 1, "bar": 2 }` | `{ "$unset": { "foo": true }, "$set": { "a.b": 3 } }` | `{ bar: 2, a: { b: 3 } }` |

## Usage

Install `rus-diff` in your project:

    npm install rus-diff --save

Usage example:

    var diff = require('rus-diff').diff

    var a = {
      foo: {
        bb: {
          inner: {
            this_is_a: 1,
            to_rename: "Hello"
          }
        },
        aa: 1
      },
      bar: 1,
      replace_me: 1
    }

    var b = {
      foo: {
        bb: {
          inner: {
            this_is_b: 2
          }
        },
        cc: {
          new_val: 2
        }
      },
      bar2: 2,
      zz: 2,
      renamed: "Hello",
      replace_me: 2
    }

    console.log(diff(a, b))

Produces diff:

    { '$rename': { 'foo.bb.inner.to_rename': 'renamed' },
      '$unset': { bar: true, 'foo.aa': true, 'foo.bb.inner.this_is_a': true },
      '$set':
       { bar2: 2,
         'foo.bb.inner.this_is_b': 2,
         'foo.cc': { new_val: 2 },
         replace_me: 2,
         zz: 2 } }

For more usage examples please see [spec](spec) directory.

Exported functions:

    // Generate diff between a and b JSON objects.
    // prefix can be set to an array or string to scope (prefix) keys,
    //   ie. 'foo.bar' means all changes will have keys starting with 'foo.bar...'.
    // options.inc = true can be set to enable $inc part for number changes.
    diff(a, b, prefix = [], options = {})

    // Apply delta diff on the JSON object a. If you don't want to mutate a you
    // can clone it before passing to apply:
    //   apply(clone(a), delta)
    apply(a, delta)

And some less important, utility functions:

    // JSON object deep copy.
    clone(a)

    // Resolve key path on the object. Returns a tuple [a, path] where a
    // is resolved object and path is an array of last component or multiple
    // unresolved components.
    //
    // a - object
    // path - an array or dot separated key path
    //
    // For example, having a document:
    //
    //   var a = { hello: { in: { nested: { world: '!' } } } }
    //
    //   resolve a, 'hello.in.nested'
    //
    // Returns [ { nested: { world: '!' } }, [ 'nested' ] ]
    //
    //   resolve a, 'hello.in.nested.something.other'
    //
    // Returns [ { world: '!' }, [ 'something', 'other' ] ]
    //
    resolve(a, path)

    // Convert non array path into array based key path.
    arrize(path)
