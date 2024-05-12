-- Removes images (<img> if HTML) from the document

function Image(elem)
  return {}
end

function Div(elem)
  return elem.content
end

function Span(elem)
  return elem.content
end

function Link(elem)
  return elem.content
end
