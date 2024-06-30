defmodule SheetexTest do
  import Dotenvy
  use ExUnit.Case
  doctest Sheetex

  test "happy path test" do
    {:ok, result} =
      Sheetex.fetch_rows(
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

  test "accepts range parameter" do
    {:ok, result} =
      Sheetex.fetch_rows(
        test_sheet_id(),
        key: api_key(),
        range: "A1:B2"
      )

    assert ^result = [["col1", "col2"], [1, 1]]
  end

  defp api_key do
    source!([".env.testing"])["GOOGLE_SHEETS_API_KEY"]
  end

  defp test_sheet_id do
    "1YPXTmkjSSwccwek96w5l25deDH6dUITENXC2fmSgwJg"
  end
end
