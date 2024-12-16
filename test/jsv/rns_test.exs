defmodule JSV.RNSTest do
  alias JSV.RNS
  use ExUnit.Case, async: true

  describe "derive from fully qualified" do
    test "derive path" do
      assert {:ok, "http://example.com/a/b"} = RNS.derive("http://example.com", "/a/b")
      assert {:ok, "http://example.com/b"} = RNS.derive("http://example.com/a", "b")
      assert {:ok, "http://example.com/a/b"} = RNS.derive("http://example.com/a/", "b")
    end

    test "replace everything" do
      assert {:ok, "http://second.host/xxx/yyy"} = RNS.derive("http://example.com/a/", "http://second.host/xxx/yyy")
    end

    test "fragment does not belong to the RNS" do
      assert {:ok, "http://example.com/a"} = RNS.derive("http://example.com/", "/a#some_fragment")
    end

    test "keep qs" do
      assert {:ok, "http://example.com/a/b?a=1&b=2"} = RNS.derive("http://example.com", "/a/b?a=1&b=2")
    end
  end

  describe "derive from root" do
    test "accepts and returns root" do
      assert {:ok, :root} = RNS.derive(:root, "#some_fragment")
      assert {:error, _} = RNS.derive(:root, "some_path#some_fragment")
    end
  end

  describe "URNs" do
    test "derive an URN" do
      assert {:ok, "urn:isbn:1234?a=1"} = RNS.derive("urn:isbn:1234?a=1", "#some_fragment")
    end
  end
end
