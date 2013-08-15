# Returns predictably ordered JSON

root = exports ? this

root.SortedJSON =
  ok: (value) ->
    if (value instanceof Array) or (typeof (value) in ["number", "string", "boolean", "object"]) or (value is undefined)
      true
    else
      false

  decode: (string) ->
    $.parseJSON(string)

  encode: (value, depth=0, done=[]) ->
    throw new TypeError("Structure contains circular references - #{value.toString()}") if (value in done)
    throw new TypeError("Structure is too deep - depth = #{depth}") if depth >= 512
    
    # Simple types
    if value is null or typeof (value) is "undefined"
      return "null"
    else if typeof (value) is "number"
      return String(value)
    else if typeof (value) is "string"
      return "\"" + value.replace(/\\/g, "\\\\").replace(/"/g, "\\\"").replace(/\n/g, "\\n").replace(/\r/g, "\\r") + "\""
    else if (value is true) or (value is false)
      return ((if value then "true" else "false"))

    # Container types
    else if value instanceof Array
      str = "["
      i = 0
      while i < value.length
        if @ok(value[i])
          str += ", "  if str.length > 1
          str += @encode(value[i], depth + 1, done.concat([value]))
        i += 1
      return str + "]"
    else if value instanceof Object
      str = "{"
      
      keys = (key for key of value when @ok(value[key])).sort()

      for key, i in keys
        str += ", " if i > 0
        str += @encode(key.toString(), depth + 1) + ": " + @encode(value[key], depth + 1, done.concat([value]))

      return str + "}"
    "null" # Shouldn't occur

