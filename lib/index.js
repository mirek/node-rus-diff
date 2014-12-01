(function() {
  var apply, arrize, clone, diff, isRealNumber, resolve,
    __slice = [].slice;

  isRealNumber = function() {
    var args;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return args.every(function(e) {
      return (typeof e === 'number') && (isNaN(e) === false) && (e !== +Infinity) && (e !== -Infinity);
    });
  };

  diff = function(a, b, stack, options, top, garbage) {
    var aI, aKey, aKeys, aN, aVal, bI, bKey, bKeys, bN, bVal, collect, delta, e, incA, k, k2, key, setB, unsetA, v, v2, _i, _len, _ref;
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
      var key, _name;
      key = (stack.concat(aKeys[i])).join('.');
      delta.$unset[key] = true;
      return (garbage[_name = a[aKeys[i]]] || (garbage[_name] = [])).push(key);
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
          case !((typeof aVal === 'object') && (typeof bVal === 'object')):
            _ref = diff(aVal, bVal, stack.concat([aKey]), options, false, garbage);
            for (k in _ref) {
              v = _ref[k];
              for (k2 in v) {
                v2 = v[k2];
                delta[k][k2] = v2;
              }
            }
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
        var _ref1, _results;
        _ref1 = delta.$set;
        _results = [];
        for (k in _ref1) {
          v = _ref1[k];
          if ((garbage[v] != null) && (key = garbage[v].pop())) {
            _results.push([k, key]);
          }
        }
        return _results;
      })();
      for (_i = 0, _len = collect.length; _i < _len; _i++) {
        e = collect[_i];
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
    while ((k = stack.shift()) !== void 0) {
      if (e[k] !== void 0) {
        e = e[k];
      } else {
        stack.unshift(k);
        break;
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
    var k, n, n1, n2, o, o1, o2, v, _name, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8;
    if (delta != null) {
      if (delta.$rename != null) {
        _ref = delta.$rename;
        for (k in _ref) {
          v = _ref[k];
          _ref1 = resolve(a, k), o1 = _ref1[0], n1 = _ref1[1];
          _ref2 = resolve(a, v), o2 = _ref2[0], n2 = _ref2[1];
          if ((o1 != null) && n1.length === 1) {
            if ((o2 != null) && n2.length === 1) {
              o2[n2[0]] = o1[n1[0]];
              delete o1[n1[0]];
            } else {
              throw new Error("" + o2 + "/" + n2 + " - couldn't resolve first for " + a + " " + v);
            }
          } else {
            throw new Error("" + o1 + "/" + n1 + " - couldn't resolve second for " + a + " " + k);
          }
        }
      }
      if (delta.$set != null) {
        _ref3 = delta.$set;
        for (k in _ref3) {
          v = _ref3[k];
          _ref4 = resolve(a, k, {
            force: true
          }), o = _ref4[0], n = _ref4[1];
          if ((o != null) && n.length === 1) {
            o[n[0]] = v;
          } else {
            throw new Error("" + o + "/" + n + " - couldn't set for " + a + " " + k);
          }
        }
      }
      if (delta.$inc != null) {
        _ref5 = delta.$inc;
        for (k in _ref5) {
          v = _ref5[k];
          _ref6 = resolve(a, k, {
            force: true
          }), o = _ref6[0], n = _ref6[1];
          if ((o != null) && n.length === 1) {
            if (o[_name = n[0]] == null) {
              o[_name] = 0;
            }
            o[n[0]] += v;
          } else {
            throw new Error("" + o + "/" + n + " - couldn't set for " + a + " " + k);
          }
        }
      }
      if (delta.$unset != null) {
        _ref7 = delta.$unset;
        for (k in _ref7) {
          v = _ref7[k];
          _ref8 = resolve(a, k), o = _ref8[0], n = _ref8[1];
          if ((o != null) && n.length === 1) {
            delete o[n[0]];
          } else {
            throw new Error("" + o + "/" + n + " - couldn't unset for " + a + " " + k);
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
    resolve: resolve,
    rusDiff: diff
  };

}).call(this);
