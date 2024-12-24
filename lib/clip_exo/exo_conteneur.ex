defmodule ExoConteneur do
  defstruct type: nil, lines: [], options: []

end

defmodule ExoLine do
  defstruct type: nil, content: nil, classes: nil, tline: nil
end