defmodule Sheetex do
  @moduledoc """
  For when you just want to fetch some rows from a Google Sheet.

  See `fetch_rows/2` for more information.
  """

  alias GoogleApi.Sheets
  alias GoogleApi.Sheets.V4.Model

  @type option() :: {:range, String.t()} | {:key, String.t()} | {:oauth_token, String.t()}
  @type rows() :: list(list() | nil) | nil

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

  ## Output
  - The output includes rows up to the last non-empty row in the sheet
    (or within the specified range).
  - For each non-empty row, the result contains a list of cell values up
    to the rightmost non-empty cell.
  - Empty rows are represented as `nil`.
  """

  @spec fetch_rows(String.t(), [option]) :: {:ok, rows()} | {:error, integer()}
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
        %Model.Sheet{data: [%Model.GridData{rowData: rows} | _]} = sheet

        {:ok, parse_rows(rows)}

      {:error, %Tesla.Env{status: status}} ->
        {:error, status}
    end
  end

  @doc """
  See `fetch_rows/2`.
  """
  @spec fetch_rows!(String.t(), [option]) :: list(list())
  def fetch_rows!(spreadsheet_id, opts) do
    case fetch_rows(spreadsheet_id, opts) do
      {:ok, result} -> result
      {:error, message} -> raise("Error. Status: " <> Integer.to_string(message))
    end
  end

  defp parse_rows(rows) do
    case rows do
      rows_list when is_list(rows_list) ->
        Enum.map(rows, fn row ->
          parse_row(row)
        end)

      _ ->
        nil
    end
  end

  defp parse_row(row) do
    case row do
      %Model.RowData{values: cell_data_items} when is_list(cell_data_items) ->
        Enum.map(cell_data_items, fn cell_data ->
          parse_cell_data(cell_data)
        end)

      _ ->
        nil
    end
  end

  defp parse_cell_data(cell_data) do
    case cell_data do
      %Model.CellData{effectiveValue: effective_value} ->
        case effective_value do
          %Model.ExtendedValue{
            stringValue: string_value,
            numberValue: number_value,
            formulaValue: formula_value,
            errorValue: error_value,
            boolValue: bool_value
          } ->
            string_value || number_value || formula_value || error_value ||
              bool_value

          _ ->
            nil
        end
    end
  end

  # Build the options for a `Sheets.V4.Api.Spreadsheets.sheets_spreadsheets_get/4` call.
  defp build_opts_for_sheets_spreadsheets_get(user_opts) do
    # The Sheets API uses `ranges` but we only return the first range,
    # hence the `range` option in singular.
    add_range = fn opts ->
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
    |> add_range.()
  end
end
