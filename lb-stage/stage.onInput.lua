function onInput(_, input)
  input = input:gsub('<lb%-stage.-</lb%-stage>', '')

  return input
end

return onInput
