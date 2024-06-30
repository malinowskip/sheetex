defmodule SheetexTest do
  import Dotenvy
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
             [1, 1],
             ["C", 2],
             [nil, nil, nil, "random value outside the table"],
             ["after empty row", "value"]
           ]
  end

  test "fetch_rows/2 returns http error code if google sheets api returns an error" do
    result = fetch_rows(test_sheet_id(), [])

    assert ^result = {:error, 403}
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
        range: "A1:B2"
      )

    assert ^result = [["col1", "col2"], [1, 1]]
  end

  test "2: an empty sheet is nil" do
    result = fetch_rows!(test_sheet_id(), key: api_key(), range: "2!A:Z")

    assert result === nil
  end

  test "3: an empty row is nil" do
    result = fetch_rows!(test_sheet_id(), key: api_key(), range: "3!A:Z")
    assert result |> Enum.count() === 3
    assert result |> Enum.at(1) === nil
  end

  test "4: correct behavior when a value is outside the table" do
    result = fetch_rows!(test_sheet_id(), key: api_key(), range: "4!A:Z")
    assert ^result = [["A", "B"], nil, nil, nil, nil, [nil, nil, nil, "Floating outside"]]
  end

  test "5: the length of each row is equal to last cell index + 1" do
    [first, second, third, fourth, fifth] =
      fetch_rows!(test_sheet_id(), key: api_key(), range: "5!A:Z")

    assert Enum.count(first) === 1
    assert Enum.count(second) === 2
    assert Enum.count(third) === 3
    assert Enum.count(fourth) === 4
    assert Enum.count(fifth) === 1
  end

  test "6: returns computed output of formulas" do
    [row] = fetch_rows!(test_sheet_id(), key: api_key(), range: "6!A:Z")

    assert ^row = [1, 1, 2]
  end

  defp api_key do
    case source!([".env.testing"])["GOOGLE_SHEETS_API_KEY"] do
      value when is_binary(value) -> value
      _ -> raise("Please provide the `GOOGLE_SHEETS_API_KEY` variable in `.env.testing`.")
    end
  end

  defp test_sheet_id do
    "1YPXTmkjSSwccwek96w5l25deDH6dUITENXC2fmSgwJg"
  end
end
