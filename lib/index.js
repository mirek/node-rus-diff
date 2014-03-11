(function() {
  var diff;

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
    if ((stack == null) || stack === '') {
      stack = [];
    } else {
      if (!Array.isArray(stack)) {
        stack = stack.toString().split('.');
      }
    }
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
        if (aVal !== bVal) {
          if ((typeof aVal === 'object') && (typeof bVal === 'object')) {
            _ref = diff(aVal, bVal, stack.concat([aKey]), options, false, garbage);
            for (k in _ref) {
              v = _ref[k];
              for (k2 in v) {
                v2 = v[k2];
                delta[k][k2] = v2;
              }
            }
          } else {
            if ((options.inc === true) && (typeof aVal === 'number') && (typeof bVal === 'number')) {
              incA(aI, bVal - aVal);
            } else {
              setB(bI);
            }
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

  if ((typeof module !== "undefined" && module !== null) && (module.exports != null)) {
    module.exports.rusDiff = diff;
    module.exports.diff = diff;
  }

}).call(this);
