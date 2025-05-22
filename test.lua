listenEdit(
  "editDisplay",
  function(triggerId, data)
    print("OK")

    local extractXMLNodesSource = getLoreBooks(triggerId, "lb__extractXMLNodes")
    if not extractXMLNodesSource or #extractXMLNodesSource == 0 then
      return data
    end

    local chunk = load(extractXMLNodesSource, "@extractXMLNodes", "b")
    print(chunk)

    return data
  end
)
