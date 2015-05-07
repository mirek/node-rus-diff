
{ digest } = require 'json-hash'

# Check if one or more arguments are real numbers (no NaN or +/-Infinity).
isRealNumber = (args...) ->
  args.every (e) ->
    (typeof e is 'number') and (isNaN(e) is false) and (e isnt +Infinity) and (e isnt -Infinity)

# Check if object is plain object.
isPlainObject = (a) ->
  a isnt null and typeof a is 'object' and a.constructor is Object

# Compute difference between two JSON objects.
#
# @param [Object, Array] a
# @param [Object, Array] b
# @param [Array, String] stack Optional scope, ie. 'foo.bar', or ['foo', 'bar'].
# @param [Object] options Options
# @option options [Boolean] inc When true $inc diff result is enabled for
#   numbers, default to false.
# @param [Boolean] top Internal, marks root invocation. Used to invoke rename.
# @param [Object] garbage Internal, holds removed values and their keys, used
#   for renaming.
# @return [Object] Difference between b and a JSON objects or false if they are
#   the same.
diff = (a, b, stack = [], options = {}, top = true, garbage = {}) ->

  # Make sure we're working on an array stack. At the root invocation it can be
  # string, null, false, undefined or an array.
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
    h = digest a[aKeys[i]]
    (garbage[h] ||= []).push key

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
      switch

        # Skip if values (scalars) are the same
        when aVal is bVal
          undefined # pass

        # Hack around typeof null is 'object' weirdness
        when (aVal? and not bVal?) or (not aVal? and bVal?)
          setB bI

        # Special case for Date support
        when (aVal instanceof Date) and (bVal instanceof Date)
          if +aVal isnt +bVal
            setB bI

        # Special case for RegExp support
        when (aVal instanceof RegExp) and (bVal instanceof RegExp)
          if "#{aVal}" isnt "#{bVal}"
            setB bI

        # Dive into any other objects
        when isPlainObject(aVal) and isPlainObject(bVal)
          for k, v of diff(aVal, bVal, stack.concat([aKey]), options, false, garbage)
            delta[k][k2] = v2 for k2, v2 of v # Merge changes

        # Skip non-plain, same objects
        when not isPlainObject(aVal) and not isPlainObject(bVal) and digest(aVal) is digest(bVal)
          undefined

        else

          # Support $inc if it was (explicitly) enabled.
          if (options.inc is true) and isRealNumber(aVal, bVal)
            incA aI, bVal - aVal
          else

            # NOTE: aVal doesn't go to garbage (as a potential rename) because
            #       MongoDB 2.4.x doesn't allow $set and $rename for the same
            #       key paths giving MongoDB error 10150: "exception: Field
            #       name duplication not allowed with modifiers"
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

    # Diff has been completed, root invocation wants to do the rename, collect
    # from garbage whatever we can.
    collect = (
      [k, key] for k, v of delta.$set when (
        h = digest v
        garbage[h]? and (key = garbage[h].pop())
      )
    )
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

# Deep copy for JSON objects.
#
# @param [Object, Array] a Object to clone
# @return [Object, Array] Cloned a object
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

# Convert a path into an array of components (key path).
#
# @param [Array, String] path
# @param [String] glue Glue/separator.
# @return [Array] Cloned or created array.
arrize = (path, glue = '.') ->
  (
    if Array.isArray(path)
      path.slice 0
    else
      switch path
        when undefined, null, false, ''
          []
        else
          path.toString().split(glue)
  ).map (e) ->
    switch e
      when undefined, null, false, ''
        null
      else
        e.toString()
  .filter (e) -> e?

# Resolve key path on an object.
#
# @example Example
#   a = hello: in: nested: world: '!'
#   console.log resolve a, 'hello.in.nested'
#   # [ { nested: { world: '!' } }, [ 'nested' ] ]
#
# @param [Object] a An object to perform resolve on.
# @param [Array, String] path Key path.
# @param [Object] options
# @option options [Boolean] force Force creation of nested objects (or arrays
#   for strictly number keys) if they don't exist. Default to false.
# @return [Array] [obj, path] tuple where obj is a resolved object and path an
#   array with last component or multiple unresolved components.
resolve = (a, path, options = {}) ->
  stack = arrize path

  last = []

  if stack.length > 0
    last.unshift stack.pop()

  # Please note we can stop resolve before reaching
  # last element. If this is the case last will have
  # multiple components if not forced.
  e = a
  if e isnt null
    while (k = stack.shift()) isnt undefined
      if e[k] isnt undefined
        e = e[k]
      else
        stack.unshift(k)
        break

  if options.force
    while (k = stack.shift()) isnt undefined

      # If the key is a number, we're creating array container, othwerwise
      # an object. Number components can only be set explicitly and will never
      # come from splitting a string so this behaviour is somehow explicitly
      # controlled by the caller (by using numbers vs strings).
      if (
        (typeof stack[0] is 'number') or
        ((stack.length == 0) and (typeof last[0] is 'number'))
      )
        e[k] = []
      else
        e[k] = {}
      e = e[k]

  else

    # Put all unresolved components into last.
    while (k = stack.pop()) isnt undefined
      last.unshift(k)

  [e, last]

# Apply delta diff on JSON object.
#
# @param [Object] a An object to apply delta on
# @param [Object] delta Diff to apply to a
# @return [Object] a object with applied diff.
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
            throw new Error "#{o2}/#{n2} - couldn't resolve first for #{a} #{v}"
        else
          throw new Error "#{o1}/#{n1} - couldn't resolve second for #{a} #{k}"

    if delta.$set?
      for k, v of delta.$set
        [o, n] = resolve a, k, force: true
        if o? and n.length == 1
          o[n[0]] = v
        else
          throw new Error "#{o}/#{n} - couldn't set for #{a} #{k}"

    if delta.$inc?
      for k, v of delta.$inc
        [o, n] = resolve a, k, force: true
        if o? and n.length == 1
          o[n[0]] ?= 0
          o[n[0]] += v
        else
          throw new Error "#{o}/#{n} - couldn't set for #{a} #{k}"

    if delta.$unset?
      for k, v of delta.$unset
        [o, n] = resolve a, k
        if o? and n.length == 1
          delete o[n[0]]
        else
          throw new Error "#{o}/#{n} - couldn't unset for #{a} #{k}"

  a

module.exports = {
  apply
  arrize
  clone
  diff
  isRealNumber
  resolve

  # NOTE: For compatibility, will be removed on next non api compatible release.
  rusDiff: diff
}
