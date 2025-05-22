function onInput(_, input)
  input = input:gsub('<lightboard%-stage.-</lightboard%-stage>', '')

  return input
end

return onInput
