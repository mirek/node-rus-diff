(function() {
  var rusDiff;

  rusDiff = function(a, b, stack, rename, garbage) {
    var aI, aKey, aKeys, aN, aVal, bI, bKey, bKeys, bN, bVal, collect, e, k, k2, key, rus, setB, unsetA, v, v2, _i, _len, _ref;
    if (stack == null) {
      stack = [];
    }
    if (rename == null) {
      rename = true;
    }
    if (garbage == null) {
      garbage = {};
    }
    aKeys = Object.keys(a).sort();
    bKeys = Object.keys(b).sort();
    aN = aKeys.length;
    bN = bKeys.length;
    aI = 0;
    bI = 0;
    rus = {
      $rename: {},
      $unset: {},
      $set: {}
    };
    unsetA = function(i) {
      var key, _name;
      key = (stack.concat(aKeys[i])).join('.');
      rus.$unset[key] = true;
      return (garbage[_name = a[aKeys[i]]] || (garbage[_name] = [])).push(key);
    };
    setB = function(i) {
      var key;
      key = (stack.concat(bKeys[i])).join('.');
      return rus.$set[key] = b[bKeys[i]];
    };
    while ((aI < aN) && (bI < bN)) {
      aKey = aKeys[aI];
      bKey = bKeys[bI];
      if (aKey === bKey) {
        aVal = a[aKey];
        bVal = b[bKey];
        if (aVal !== bVal) {
          if ((typeof aVal === 'object') && (typeof bVal === 'object')) {
            _ref = rusDiff(aVal, bVal, stack.concat([aKey]), false, garbage);
            for (k in _ref) {
              v = _ref[k];
              for (k2 in v) {
                v2 = v[k2];
                rus[k][k2] = v2;
              }
            }
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
    if (rename) {
      collect = (function() {
        var _ref1, _results;
        _ref1 = rus.$set;
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
        rus.$rename[key] = k;
        delete rus.$unset[key];
        delete rus.$set[k];
      }
    }
    for (k in rus) {
      if (Object.keys(rus[k]).length === 0) {
        delete rus[k];
      }
    }
    return rus;
  };

  if ((typeof module !== "undefined" && module !== null) && (module.exports != null)) {
    module.exports.rusDiff = rusDiff;
  }

}).call(this);
