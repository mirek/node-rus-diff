## Summary [![Build Status](https://travis-ci.org/mirek/node-json-criteria.png?branch=master)](https://travis-ci.org/mirek/node-rus-diff)

(R)emove-(U)pdate-(S)et JSON diff library can be used standalone to compute difference between two JSON objects.

Produced diff is MongoDB compatible and can be used to modify documents with `collection.update(...)`.

## Examples

### Diff

| a       | b         | diff(a, b)                     | options      |
|---------|-----------|--------------------------------|--------------|
| `{a:1}` | `{b:2}`   | `{$unset:{a:true},$set:{b:2}}` |              |
| `{a:1}` | `{b:1}`   | `{$rename:{a:'b'}}`            |              |
| `{a:1}` | `{}`      | `{$unset:{a:true}}`            |              |
| `{a:1}` | `{a:2.5}` | `{$set:{a:2.5}}`               |              |
| `{a:1}` | `{a:2.5}` | `{$inc:{a:1.5}}`               | `{inc:true}` |

### Apply

| a           | diff                               | apply(a, diff)  |
|-------------|------------------------------------|-----------------|
| `{}`        | `{$inc:{'a.b':1}}`                 | `{a:{b:1}}`     |
| `{a:1.5}`   | `{$inc:{a:-2.5}}`                  | `{a:-1}`        |
| `{a:true}`  | `{$rename:{a:'b'}}`                | `{ bar: true }` |
| `{a:1,b:2}` | `{$unset:{a:true},$set:{'c.d':3}}` | `{b:2,c:{d:3}}` |

## Usage

Install `rus-diff` in your project:

    npm install rus-diff --save

Install ES6 compatibility layer:

    npm install babel --save

Usage example:

    // Add ES6 polyfills.
    require('babel/polyfill')

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

# License

    The MIT License (MIT)

    Copyright (c) 2014 Mirek Rusin

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
