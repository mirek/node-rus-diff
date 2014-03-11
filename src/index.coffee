
# Difference between JSON objects.
#
# @param [Object] a
# @param [Object] b
# @param [Array|String] stack Optional scope.
# @param [Object] options Set options.inc to true to have $inc for numbers instead of $set.
#
# @param [Boolean] top Internal, marks root invocation. Used to invoke rename.
# @param [Object] garbage Internal, holds removed values and their keys, used for renaming.
#
# @return [Object] Difference between b - a JSON objects or false if objects are the same.
#
diff = (a, b, stack = [], options = {}, top = true, garbage = {}) ->

  # Make sure we're working on an array stack. At the root invocation it can be string,
  # null, false, undefined or an array.
  stack = arrize(stack)

  aKeys = Object.keys(a).sort()
  bKeys = Object.keys(b).sort()

  aN = aKeys.length
  bN = bKeys.length

  aI = 0
  bI = 0

  delta =
    $rename: {}
    $unset: {}
    $set: {}
    $inc: {}

  unsetA = (i) ->
    key = (stack.concat aKeys[i]).join('.')
    delta.$unset[key] = true
    (garbage[ a[aKeys[i]] ] ||= []).push key

  setB = (i) ->
    key = (stack.concat bKeys[i]).join('.')
    delta.$set[key] = b[bKeys[i]]

  incA = (i, d) ->
    key = (stack.concat aKeys[i]).join('.')
    delta.$inc[key] = d

  while (aI < aN) and (bI < bN)
    aKey = aKeys[aI]
    bKey = bKeys[bI]

    if aKey is bKey
      aVal = a[aKey]
      bVal = b[bKey]
      if aVal isnt bVal
        if (typeof aVal is 'object') and (typeof bVal is 'object')
          for k, v of diff(aVal, bVal, stack.concat([aKey]), options, false, garbage)

            # Merge changes
            for k2, v2 of v
              delta[k][k2] = v2
        else

          # TODO: What about Infinity/-Infinity?
          if (options.inc is true) and (typeof aVal is 'number') and (typeof bVal is 'number')
            incA aI, bVal - aVal
          else

            # NOTE: aVal doesn't go to garbage (as a potential rename) because MongoDB 2.4.x doesn't allow $set
            #       and $rename for the same key paths giving MongoDB error 10150: "exception: Field name duplication
            #       not allowed with modifiers"
            setB bI
      ++aI
      ++bI
    else
      if aKey < bKey
        unsetA aI
        ++aI
      else
        setB bI
        ++bI

  # Finish remaining a keys if any left.
  while aI < aN
    unsetA aI++

  # Finish remaining b keys if any left.
  while bI < bN
    setB bI++

  if top

    # Diff has been completed, root invocation wants to do the rename, collect from garbage
    # whatever we can.
    collect = ([k, key] for k, v of delta.$set when garbage[v]? and (key = garbage[v].pop()))
    for e in collect
      [k, key] = e
      delta.$rename[key] = k
      delete delta.$unset[key]
      delete delta.$set[k]

  # Return non-empty modifications only.
  for k of delta
    if Object.keys(delta[k]).length is 0
      delete delta[k]

  # Return false if there are no differences.
  if Object.keys(delta).length == 0
    delta = false

  delta

clone = (a) ->
  switch
    when (not a?) or (typeof(a) isnt 'object')
      a
    when (a instanceof Date)
      new Date(a.getTime())
    when (a instanceof RegExp)
      f = ''
      f += 'g' if a.global?
      f += 'i' if a.ignoreCase?
      f += 'm' if a.multiline?
      f += 'y' if a.sticky?
      new RegExp(a.source, f) 
    else
      b = new a.constructor
      for k, v of a
        b[k] = clone v
      b

resolve = (a, path) ->
  if toString.call(path) is '[object String]'
    key

# @return Cloned or created array.
arrize = (path, glue = '.') ->
  if !path? or path is ''
    []
  else
    if Array.isArray(path)
      path.slice 0
    else
      path.toString().split(glue)

# @return [Array] Tuple with two elements, first is an object and second is an array with last component or multiple unresolved components.
resolve = (a, path) ->
  stack = arrize path

  # We will always resolve to at least single name.
  last = [stack.pop()]

  # Please note we can stop resolve before reaching
  # last element. If this is the case last will have
  # multiple components.
  e = a
  while (k = stack.shift()) isnt undefined
    if e[k] isnt undefined
      e = e[k]
    else
      stack.unshift(k)
      break

  # Put all unresolved components into last.
  while (k = stack.pop()) isnt undefined
    last.unshift(k)

  [e, last]

# Apply delta diff on JSON object.
apply = (a, delta) ->
  if delta?
    if delta.$rename?
      for k, v of delta.$rename
        [o1, n1] = resolve a, k
        [o2, n2] = resolve a, v
        if o1? and n1.length == 1
          if o2? and n2.length == 1
            o2[n2[0]] = o1[n1[0]]
            delete o1[n1[0]]
          else
            throw "#{o2}/#{n2} - couldn't resolve first for #{a} #{v}"
        else
          throw "#{o1}/#{n1} - couldn't resolve second for #{a} #{k}"
    if delta.$set?
      for k, v of delta.$set
        [o, n] = resolve a, k
        if o? and n.length == 1
          o[n[0]] = v
        else
          throw "#{o}/#{n} - couldn't set for #{a} #{k}"
    if delta.$inc?
      for k, v of delta.$inc
        [o, n] = resolve a, k
        if o? and n.length == 1
          o[n[0]] += v
        else
          throw "#{o}/#{n} - couldn't set for #{a} #{k}"
    if delta.$unset?
      for k, v of delta.$unset
        [o, n] = resolve a, k
        if o? and n.length == 1
          delete o[n[0]]
        else
          throw "#{o}/#{n} - couldn't unset for #{a} #{k}"
  a

if module? and module.exports?

  # NOTE: For compatibility, will be removed on next non api compatible release.
  module.exports.rusDiff = diff

  module.exports.diff = diff
  module.exports.clone = clone
  module.exports.apply = apply
  module.exports.arrize = arrize
  module.exports.resolve = resolve

