
# Difference between JSON objects.
#
# @param [Object] a
# @param [Object] b
# @param [Array] stack Optional scope.
# @param [Boolean] rename Internal
# @param [Object] garbage Internal
#
# @return [Object] Difference between b - a JSON objects.
#
rusDiff = (a, b, stack = [], rename = true, garbage = {}) ->

  # Sorted lists of keys.
  aKeys = Object.keys(a).sort()
  bKeys = Object.keys(b).sort()

  # Number of keys.
  aN = aKeys.length
  bN = bKeys.length

  # Key indices.
  aI = 0
  bI = 0

  # Result.
  rus =
    $rename: {}
    $unset: {}
    $set: {}

  # Unset 
  unsetA = (i) ->
    key = (stack.concat aKeys[i]).join('.')
    rus.$unset[key] = true
    (garbage[ a[aKeys[i]] ] ||= []).push key

  setB = (i) ->
    key = (stack.concat bKeys[i]).join('.')
    rus.$set[key] = b[bKeys[i]]

  while (aI < aN) and (bI < bN)
    aKey = aKeys[aI]
    bKey = bKeys[bI]

    if aKey is bKey
      aVal = a[aKey]
      bVal = b[bKey]
      if aVal isnt bVal
        if (typeof aVal is 'object') and (typeof bVal is 'object')
          for k, v of rusDiff(aVal, bVal, stack.concat([aKey]), false, garbage)

            # Merge changes
            for k2, v2 of v
              rus[k][k2] = v2
        else

          # At least one is not an Object (hash), b overwrites a.
          #
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

  if rename

    # Diff has been completed, root invocation wants to do the rename, collect from garbage
    # whatever we can.
    collect = ([k, key] for k, v of rus.$set when garbage[v]? and (key = garbage[v].pop()))
    for e in collect
      [k, key] = e
      rus.$rename[key] = k
      delete rus.$unset[key]
      delete rus.$set[k]

  # Return non-empty modifications only.
  for k of rus
    if Object.keys(rus[k]).length is 0
      delete rus[k]

  rus

if module? and module.exports?
  module.exports.rusDiff = rusDiff
