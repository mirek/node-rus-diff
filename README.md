## Summary

(R)emove-(U)pdate-(S)et JSON diff library can be used standalone to compute difference between two JSON objects.

Produced diff is MongoDB compatible and can be used to modify documents with `collection.update(...)`.

## Usage

Install `rus-diff` in your project:

    npm install rus-diff --save

Usage example:

    var rusDiff = require('rus-diff').rusDiff
    var a = {
        one: 1,
        foo: 'hello'
    }
    var b = {
        two: 2,
        bar: 'hello'
    }
    console.log(rusDiff(a, b))

    // { '$rename': { foo: 'bar' },
    //  '$unset': { one: true },
    //  '$set': { two: 2 } }

For more usage examples please see [spec](spec) directory.
