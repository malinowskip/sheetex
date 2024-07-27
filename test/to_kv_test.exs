defmodule SheetexTest.ToKv do
  use ExUnit.Case, async: true

  test "happy path test" do
    data = [[:a, :b, :c], [1, 2, 3], [1, 2, 3]]

    result = Sheetex.to_kv(data)

    assert ^result = [%{c: 3, a: 1, b: 2}, %{c: 3, a: 1, b: 2}]
  end

  test "empty values are represented as nil" do
    data = [[:a, :b, :c], [], [1, 2], [1, 2], []]

    result = Sheetex.to_kv(data)

    assert ^result = [
             %{a: nil, b: nil, c: nil},
             %{c: nil, a: 1, b: 2},
             %{c: nil, a: 1, b: 2},
             %{a: nil, b: nil, c: nil}
           ]
  end

  test "values that don’t have a column are dropped" do
    data = [[:a, :b], [1, 2, 3], [1, 2, 3]]

    result = Sheetex.to_kv(data)

    assert ^result = [%{a: 1, b: 2}, %{a: 1, b: 2}]
  end

  test "strings are converted to atoms with [atom_keys: true]" do
    data = [["a", "b"], [1, 2, 3], [1, 2, 3]]
    result = Sheetex.to_kv(data, atom_keys: true)
    assert ^result = [%{a: 1, b: 2}, %{a: 1, b: 2}]
  end

  test "custom headers" do
    data = [[1, 2], [1, 2, 3, 4]]
    result = Sheetex.to_kv(data, headers: [:a, :b, :c])
    assert ^result = [%{a: 1, b: 2, c: nil}, %{a: 1, b: 2, c: 3}]
  end

  test "custom headers are converted to atoms with [atom_keys: true]" do
    data = [[1, 2, 3], [1, 2, 3]]
    result = Sheetex.to_kv(data, headers: ["a", "b", "c"], atom_keys: true)
    assert ^result = [%{a: 1, b: 2, c: 3}, %{a: 1, b: 2, c: 3}]
  end

  test "[atom_keys: true] doesn’t throw if atoms provided" do
    data = [[:a, :b], [1, 2], [1, 2]]
    result = Sheetex.to_kv(data, atom_keys: true)
    assert ^result = [%{a: 1, b: 2}, %{a: 1, b: 2}]
  end
end
