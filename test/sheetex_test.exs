defmodule SheetexTest do
  use ExUnit.Case, async: true
  doctest Sheetex
  import Sheetex

  test "1: happy path test" do
    result =
      fetch_rows!(
        test_sheet_id(),
        key: api_key()
      )

    assert ^result = [
             ["col1", "col2"],
             [],
             [1, 1],
             ["C", 2],
             [nil, nil, nil, "random value outside the table"],
             ["after empty row", "value"]
           ]

    kv = Sheetex.to_kv(result)

    assert ^kv = [
             %{"col1" => nil, "col2" => nil},
             %{"col1" => 1, "col2" => 1},
             %{"col1" => "C", "col2" => 2},
             %{"col1" => nil, "col2" => nil},
             %{"col1" => "after empty row", "col2" => "value"}
           ]
  end

  test "fetch_rows/2 returns error message if google sheets api returns an error" do
    result = fetch_rows(test_sheet_id(), [])

    assert {:error, message} = result
    assert is_binary(message)
  end

  test "fetch_rows!/2 raises an error on failure" do
    assert_raise RuntimeError, fn ->
      fetch_rows!(test_sheet_id(), [])
    end
  end

  test "1: accepts range parameter" do
    result =
      fetch_rows!(
        test_sheet_id(),
        key: api_key(),
        range: "A1:B3"
      )

    assert ^result = [["col1", "col2"], [], [1, 1]]
  end

  test "2: an empty sheet is nil" do
    result = fetch_rows!(test_sheet_id(), key: api_key(), range: "2!A:Z")

    assert result === nil
  end

  test "3: an empty row is an empty list" do
    result = fetch_rows!(test_sheet_id(), key: api_key(), range: "3!A:Z")
    assert result |> Enum.count() === 3
    assert result |> Enum.at(1) === []
  end

  test "4: correct behavior when a value is outside the table" do
    result = fetch_rows!(test_sheet_id(), key: api_key(), range: "4!A:Z")
    assert ^result = [["A", "B"], [], [], [], [], [nil, nil, nil, "Floating outside"]]
  end

  test "5: the length of each row is equal to last cell index + 1" do
    [first, second, third, fourth, fifth, sixth] =
      fetch_rows!(test_sheet_id(), key: api_key(), range: "5!A:Z")

    assert Enum.count(first) === 1
    assert Enum.count(second) === 2
    assert Enum.count(third) === 3
    assert Enum.count(fourth) === 4
    assert Enum.count(fifth) === 0
    assert Enum.count(sixth) === 1
  end

  test "6: returns computed output of formulas" do
    [row] = fetch_rows!(test_sheet_id(), key: api_key(), range: "6!A:Z")

    assert ^row = [1, 1, 2]
  end

  test "7: data types" do
    [
      _,
      [string_cell, integer_cell, float_cell, boolean_cell, nil_cell, error_cell]
    ] = fetch_rows!(test_sheet_id(), key: api_key(), range: "7!A:Z")

    assert is_binary(string_cell)
    assert is_integer(integer_cell)
    assert is_float(float_cell)
    assert is_boolean(boolean_cell)
    assert is_nil(nil_cell)
    assert %{message: _, type: _} = error_cell
  end

  test "to_kv: happy path test" do
    data = [[:a, :b, :c], [1, 2, 3], [1, 2, 3]]

    result = Sheetex.to_kv(data)

    assert ^result = [%{c: 3, a: 1, b: 2}, %{c: 3, a: 1, b: 2}]
  end

  test "to_kv: empty values are represented as nil" do
    data = [[:a, :b, :c], [], [1, 2], [1, 2], []]

    result = Sheetex.to_kv(data)

    assert ^result = [
             %{a: nil, b: nil, c: nil},
             %{c: nil, a: 1, b: 2},
             %{c: nil, a: 1, b: 2},
             %{a: nil, b: nil, c: nil}
           ]
  end

  test "to_kv: values that don’t have a column are dropped" do
    data = [[:a, :b], [1, 2, 3], [1, 2, 3]]

    result = Sheetex.to_kv(data)

    assert ^result = [%{a: 1, b: 2}, %{a: 1, b: 2}]
  end

  test "to_kv: atom keys" do
    data = [["a", "b"], [1, 2, 3], [1, 2, 3]]
    result = Sheetex.to_kv(data, atom_keys: true)
    assert ^result = [%{a: 1, b: 2}, %{a: 1, b: 2}]
  end

  test "8: iris dataset" do
    result =
      fetch_rows!(test_sheet_id(), key: api_key(), range: "8!A1:E3")

    kv = Sheetex.to_kv(result)

    assert ^kv = [
             %{
               "petal_length" => 1.4,
               "petal_width" => 0.2,
               "sepal_length" => 5.1,
               "sepal_width" => 3.5,
               "species" => "Iris-setosa"
             },
             %{
               "petal_length" => 1.4,
               "petal_width" => 0.2,
               "sepal_length" => 4.9,
               "sepal_width" => 3,
               "species" => "Iris-setosa"
             }
           ]
  end

  test "9: empty header in the middle" do
    result =
      fetch_rows!(test_sheet_id(), key: api_key(), range: "9!A1:C3")

    kv =
      Sheetex.to_kv(result)

    assert ^kv = [%{"a" => 1, "c" => 3}]
  end

  defp api_key do
    System.fetch_env!("GOOGLE_SHEETS_API_KEY")
  end

  defp test_sheet_id do
    "1YPXTmkjSSwccwek96w5l25deDH6dUITENXC2fmSgwJg"
  end
end
