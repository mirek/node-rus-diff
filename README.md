## Summary

(R)emove-(U)pdate-(S)et JSON diff library can be used standalone to compute difference between two JSON objects.

Produced diff is MongoDB compatible and can be used to modify documents with `collection.update(...)`.

## Usage

Install `rus-diff` in your project:

    npm install rus-diff --save

Usage example:

    var rusDiff = require('rus-diff').rusDiff

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

    console.log(rusDiff(a, b))

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
