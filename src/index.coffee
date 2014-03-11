
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
  if !stack? or stack is ''
    stack = []
  else
    unless Array.isArray(stack)
      stack = stack.toString().split('.')

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

# clone = (a) ->
#   switch
#   when not a? or typeof a isnt 'object'
#     a
#   when a instanceof Date
#     new Date(a.getTime())
#   when 
#     if a instanceof RegExp
#       f = ''
#       f += 'g' if a.global?
#       f += 'i' if a.ignoreCase?
#       f += 'm' if a.multiline?
#       f += 'y' if a.sticky?
#       new RegExp(a.source, f) 
#   else
#     b = new a.constructor
#     for k, v of a
#       b[k] = clone v
#     b
# 
# apply = (a, delta) ->
#   if delta?
#     if delta.$rename?
#     if delta.$unset?
#     if delta.$set?
#     if delta.$inc?
#   a

if module? and module.exports?

  # NOTE: For compatibility, will be removed on next non api compatible release.
  module.exports.rusDiff = diff

  module.exports.diff = diff
  # module.exports.clone = clone
  # module.exports.apply = apply

