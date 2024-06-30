defmodule Sheetex do
  @moduledoc """
    For when you just want to fetch some rows from a Google Sheet.
    See `fetch_rows/2` for more information.
  """
  alias GoogleApi.Sheets
  alias GoogleApi.Sheets.V4.Model

  @doc """
  Fetch rows from a Google Sheet.

  For this to work, you need an API key or an OAuth token that will
  be passed to the Google Sheets API. See [Google’s official
  authorization
  docs](https://developers.google.com/workspace/guides/get-started).

  ## Options
  **You must provide either `key` OR `oauth_token` for authorization.**
  - `key` – API key.
  - `oauth_token` – OAuth token.
  - `range` – Use this if you want to fetch a specific range from a spreadsheet using the [A1
    notation](https://developers.google.com/sheets/api/guides/concepts#expandable-1).
  """
  def fetch_rows(spreadsheet_id, opts) do
    case Sheets.V4.Api.Spreadsheets.sheets_spreadsheets_get(
           Sheets.V4.Connection.new(),
           spreadsheet_id,
           build_opts_for_sheets_spreadsheets_get(opts)
         ) do
      {:ok, sheets} ->
        # Grab only the first sheet.
        %Model.Spreadsheet{sheets: [sheet | _]} = sheets

        # Grab only the first instance of `GridData` for the sheet.
        %Model.Sheet{data: [%Model.GridData{rowData: row_data_items} | _]} = sheet

        parsed =
          Enum.map(row_data_items, fn %Model.RowData{values: values} ->
            Enum.map(values, fn %Model.CellData{effectiveValue: effective_value} ->
              %Model.ExtendedValue{
                stringValue: string_value,
                numberValue: number_value,
                formulaValue: formula_value,
                errorValue: error_value,
                boolValue: bool_value
              } = effective_value

              string_value || number_value || formula_value || error_value || bool_value
            end)
          end)

        {:ok, parsed}

      {:error, %Tesla.Env{status: status}} ->
        {:error, status}
    end
  end

  # Build the options for a `Sheets.V4.Api.Spreadsheets.sheets_spreadsheets_get/4` call.
  defp build_opts_for_sheets_spreadsheets_get(user_opts) do
    # The Sheets API uses `ranges` but we only fetch the first range,
    # hence the `range` option in singular.
    add_ranges = fn opts ->
      case user_opts[:range] do
        v when is_binary(v) -> opts ++ [{:ranges, v}]
        _ -> opts
      end
    end

    # API key
    add_key = fn opts ->
      case user_opts[:key] do
        v when is_binary(v) -> opts ++ [{:key, v}]
        _ -> opts
      end
    end

    add_oauth_token = fn opts ->
      case user_opts[:oauth_token] do
        v when is_binary(v) -> opts ++ [{:oauth_token, v}]
        _ -> opts
      end
    end

    [
      # Apply field mask to only get the value of each cell in the spreadsheet/range.
      # see https://developers.google.com/sheets/api/guides/field-masks
      {:fields, "sheets.data(rowData(values(effectiveValue)))"}
    ]
    |> add_key.()
    |> add_oauth_token.()
    |> add_ranges.()
  end

  @doc """
  See `fetch_rows/2`
  """
  def fetch_rows!(spreadsheet_id, opts) do
    case fetch_rows(spreadsheet_id, opts) do
      {:ok, result} -> result
      {:error, message} -> raise(message)
    end
  end

  @doc """
  Transform a list of rows into a list of maps using the first row as the header row.

  ## Examples

      iex> rows = [["A", "B"], ["A1", "B2"], ["A2", "B2"]]
      iex> Sheetex.to_kv(rows)
      [
        %{
          "A" => "A1",
          "B" => "B2"
        },
        %{
          "A" => "A2",
          "B" => "B2"
        }
      ]

  """
  @spec to_kv(list(list())) :: list(map())
  def to_kv(result) when is_list(result) do
    [header_row | rows] = result

    Enum.map(rows, fn row ->
      Enum.zip(header_row, row) |> Map.new()
    end)
  end
end
