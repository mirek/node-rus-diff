(function() {
  var apply, arrize, clone, diff, digest, isPlainObject, isRealNumber, resolve,
    slice = [].slice;

  digest = require('json-hash').digest;

  isRealNumber = function() {
    var args;
    args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    return args.every(function(e) {
      return (typeof e === 'number') && (isNaN(e) === false) && (e !== +Infinity) && (e !== -Infinity);
    });
  };

  isPlainObject = function(a) {
    return a !== null && typeof a === 'object' && a.constructor === Object;
  };

  diff = function(a, b, stack, options, top, garbage) {
    var aI, aKey, aKeys, aN, aVal, bI, bKey, bKeys, bN, bVal, collect, delta, e, h, incA, j, k, k2, key, len, ref, setB, unsetA, v, v2;
    if (stack == null) {
      stack = [];
    }
    if (options == null) {
      options = {};
    }
    if (top == null) {
      top = true;
    }
    if (garbage == null) {
      garbage = {};
    }
    stack = arrize(stack);
    aKeys = Object.keys(a).sort();
    bKeys = Object.keys(b).sort();
    aN = aKeys.length;
    bN = bKeys.length;
    aI = 0;
    bI = 0;
    delta = {
      $rename: {},
      $unset: {},
      $set: {},
      $inc: {}
    };
    unsetA = function(i) {
      var h, key;
      key = (stack.concat(aKeys[i])).join('.');
      delta.$unset[key] = true;
      h = digest(a[aKeys[i]]);
      return (garbage[h] || (garbage[h] = [])).push(key);
    };
    setB = function(i) {
      var key;
      key = (stack.concat(bKeys[i])).join('.');
      return delta.$set[key] = b[bKeys[i]];
    };
    incA = function(i, d) {
      var key;
      key = (stack.concat(aKeys[i])).join('.');
      return delta.$inc[key] = d;
    };
    while ((aI < aN) && (bI < bN)) {
      aKey = aKeys[aI];
      bKey = bKeys[bI];
      if (aKey === bKey) {
        aVal = a[aKey];
        bVal = b[bKey];
        switch (false) {
          case aVal !== bVal:
            void 0;
            break;
          case !(((aVal != null) && (bVal == null)) || ((aVal == null) && (bVal != null))):
            setB(bI);
            break;
          case !((aVal instanceof Date) && (bVal instanceof Date)):
            if (+aVal !== +bVal) {
              setB(bI);
            }
            break;
          case !((aVal instanceof RegExp) && (bVal instanceof RegExp)):
            if (("" + aVal) !== ("" + bVal)) {
              setB(bI);
            }
            break;
          case !(isPlainObject(aVal) && isPlainObject(bVal)):
            ref = diff(aVal, bVal, stack.concat([aKey]), options, false, garbage);
            for (k in ref) {
              v = ref[k];
              for (k2 in v) {
                v2 = v[k2];
                delta[k][k2] = v2;
              }
            }
            break;
          case !(!isPlainObject(aVal) && !isPlainObject(bVal) && digest(aVal) === digest(bVal)):
            void 0;
            break;
          default:
            if ((options.inc === true) && isRealNumber(aVal, bVal)) {
              incA(aI, bVal - aVal);
            } else {
              setB(bI);
            }
        }
        ++aI;
        ++bI;
      } else {
        if (aKey < bKey) {
          unsetA(aI);
          ++aI;
        } else {
          setB(bI);
          ++bI;
        }
      }
    }
    while (aI < aN) {
      unsetA(aI++);
    }
    while (bI < bN) {
      setB(bI++);
    }
    if (top) {
      collect = (function() {
        var ref1, results;
        ref1 = delta.$set;
        results = [];
        for (k in ref1) {
          v = ref1[k];
          if ((h = digest(v), (garbage[h] != null) && (key = garbage[h].pop()))) {
            results.push([k, key]);
          }
        }
        return results;
      })();
      for (j = 0, len = collect.length; j < len; j++) {
        e = collect[j];
        k = e[0], key = e[1];
        delta.$rename[key] = k;
        delete delta.$unset[key];
        delete delta.$set[k];
      }
    }
    for (k in delta) {
      if (Object.keys(delta[k]).length === 0) {
        delete delta[k];
      }
    }
    if (Object.keys(delta).length === 0) {
      delta = false;
    }
    return delta;
  };

  clone = function(a) {
    var b, f, k, v;
    switch (false) {
      case !((a == null) || (typeof a !== 'object')):
        return a;
      case !(a instanceof Date):
        return new Date(a.getTime());
      case !(a instanceof RegExp):
        f = '';
        if (a.global != null) {
          f += 'g';
        }
        if (a.ignoreCase != null) {
          f += 'i';
        }
        if (a.multiline != null) {
          f += 'm';
        }
        if (a.sticky != null) {
          f += 'y';
        }
        return new RegExp(a.source, f);
      default:
        b = new a.constructor;
        for (k in a) {
          v = a[k];
          b[k] = clone(v);
        }
        return b;
    }
  };

  arrize = function(path, glue) {
    if (glue == null) {
      glue = '.';
    }
    return ((function() {
      if (Array.isArray(path)) {
        return path.slice(0);
      } else {
        switch (path) {
          case void 0:
          case null:
          case false:
          case '':
            return [];
          default:
            return path.toString().split(glue);
        }
      }
    })()).map(function(e) {
      switch (e) {
        case void 0:
        case null:
        case false:
        case '':
          return null;
        default:
          return e.toString();
      }
    }).filter(function(e) {
      return e != null;
    });
  };

  resolve = function(a, path, options) {
    var e, k, last, stack;
    if (options == null) {
      options = {};
    }
    stack = arrize(path);
    last = [];
    if (stack.length > 0) {
      last.unshift(stack.pop());
    }
    e = a;
    if (e !== null) {
      while ((k = stack.shift()) !== void 0) {
        if (e[k] !== void 0) {
          e = e[k];
        } else {
          stack.unshift(k);
          break;
        }
      }
    }
    if (options.force) {
      while ((k = stack.shift()) !== void 0) {
        if ((typeof stack[0] === 'number') || ((stack.length === 0) && (typeof last[0] === 'number'))) {
          e[k] = [];
        } else {
          e[k] = {};
        }
        e = e[k];
      }
    } else {
      while ((k = stack.pop()) !== void 0) {
        last.unshift(k);
      }
    }
    return [e, last];
  };

  apply = function(a, delta) {
    var k, n, n1, n2, name, o, o1, o2, ref, ref1, ref2, ref3, ref4, ref5, ref6, ref7, ref8, v;
    if (delta != null) {
      if (delta.$rename != null) {
        ref = delta.$rename;
        for (k in ref) {
          v = ref[k];
          ref1 = resolve(a, k), o1 = ref1[0], n1 = ref1[1];
          ref2 = resolve(a, v), o2 = ref2[0], n2 = ref2[1];
          if ((o1 != null) && n1.length === 1) {
            if ((o2 != null) && n2.length === 1) {
              o2[n2[0]] = o1[n1[0]];
              delete o1[n1[0]];
            } else {
              throw new Error(o2 + "/" + n2 + " - couldn't resolve first for " + a + " " + v);
            }
          } else {
            throw new Error(o1 + "/" + n1 + " - couldn't resolve second for " + a + " " + k);
          }
        }
      }
      if (delta.$set != null) {
        ref3 = delta.$set;
        for (k in ref3) {
          v = ref3[k];
          ref4 = resolve(a, k, {
            force: true
          }), o = ref4[0], n = ref4[1];
          if ((o != null) && n.length === 1) {
            o[n[0]] = v;
          } else {
            throw new Error(o + "/" + n + " - couldn't set for " + a + " " + k);
          }
        }
      }
      if (delta.$inc != null) {
        ref5 = delta.$inc;
        for (k in ref5) {
          v = ref5[k];
          ref6 = resolve(a, k, {
            force: true
          }), o = ref6[0], n = ref6[1];
          if ((o != null) && n.length === 1) {
            if (o[name = n[0]] == null) {
              o[name] = 0;
            }
            o[n[0]] += v;
          } else {
            throw new Error(o + "/" + n + " - couldn't set for " + a + " " + k);
          }
        }
      }
      if (delta.$unset != null) {
        ref7 = delta.$unset;
        for (k in ref7) {
          v = ref7[k];
          ref8 = resolve(a, k), o = ref8[0], n = ref8[1];
          if ((o != null) && n.length === 1) {
            delete o[n[0]];
          } else {
            throw new Error(o + "/" + n + " - couldn't unset for " + a + " " + k);
          }
        }
      }
    }
    return a;
  };

  module.exports = {
    apply: apply,
    arrize: arrize,
    clone: clone,
    diff: diff,
    isRealNumber: isRealNumber,
    resolve: resolve,
    rusDiff: diff
  };

}).call(this);
