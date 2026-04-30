defmodule JSVTest do
  use ExUnit.Case, async: true

  doctest JSV, import: true, tags: [:capture_log]
end
