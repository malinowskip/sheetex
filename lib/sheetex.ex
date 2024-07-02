defmodule Sheetex do
  @moduledoc """
  For when you just want to fetch some rows from a Google Sheet.

  See `fetch_rows/2` for more information.
  """

  @type option() :: {:range, String.t()} | {:key, String.t()} | {:oauth_token, String.t()}
  @type rows() :: list(list(cell()))
  @type cell() ::
          String.t()
          | integer()
          | float()
          | boolean()
          | nil
          | %{message: String.t() | nil, type: String.t() | nil}

  @doc """
  Fetch rows from a Google Sheet.

  For this to work, you need an API key or an OAuth token that will
  be passed to the Google Sheets API. [See Google’s official
  authorization
  docs](https://developers.google.com/workspace/guides/get-started).

  ## Options
  **You must provide either `key` OR `oauth_token` for authorization.**
  - `key` – API key.
  - `oauth_token` – OAuth token.
  - `range` – Use this option if you want to fetch a specific range from a
    spreadsheet using the [A1 notation](https://developers.google.com/sheets/api/guides/concepts#expandable-1).

  ## Output
  - The output will include a list of rows up to the last non-empty row in the sheet
    (or from within the specified range).
  - For each non-empty row, the output will contain a list of cell values up
    to the rightmost non-empty cell.
  """

  @spec fetch_rows(String.t(), [option]) :: {:ok, rows()} | {:error, String.t()}
  def fetch_rows(spreadsheet_id, opts) do
    case query_google_sheets_api(spreadsheet_id, opts) do
      {:ok, body} ->
        # Grab only the first sheet.
        %{sheets: [sheet | _]} = body

        # Grab only the first range.
        %{data: [row_data | _]} = sheet

        rows =
          case row_data do
            %{rowData: rows} -> rows
            _ -> nil
          end

        result = parse_rows(rows)

        {:ok, result}

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Similar to `fetch_rows/2`, but raises an exception on failure.
  """
  @spec fetch_rows!(String.t(), [option]) :: rows()
  def fetch_rows!(spreadsheet_id, opts) do
    case fetch_rows(spreadsheet_id, opts) do
      {:ok, result} -> result
      {:error, message} -> raise("Error: #{message}")
    end
  end

  defp parse_rows(rows) when is_list(rows) do
    Enum.map(rows, fn row ->
      parse_row(row)
    end)
  end

  defp parse_rows(_), do: nil

  defp parse_row(%{values: cell_data_items}) when is_list(cell_data_items) do
    Enum.map(cell_data_items, fn cell_data ->
      parse_cell_data(cell_data)
    end)
  end

  defp parse_row(_), do: []

  defp parse_cell_data(%{effectiveValue: effective_value}) do
    case effective_value do
      %{stringValue: value} ->
        value

      %{numberValue: value} ->
        value

      %{formulaValue: value} ->
        value

      %{errorValue: value} ->
        value

      %{boolValue: value} ->
        value

      _ ->
        nil
    end
  end

  defp parse_cell_data(_), do: nil

  @spec query_google_sheets_api(String.t(), [option]) :: {:ok, map()} | {:error, String.t()}
  defp query_google_sheets_api(spreadsheet_id, opts) do
    url = "https://sheets.googleapis.com/v4/spreadsheets/" <> spreadsheet_id

    base_middlewares = [
      {Tesla.Middleware.BaseUrl, url},
      # Apply field mask to get only the effective value of each cell in the spreadsheet/range.
      # See https://developers.google.com/sheets/api/guides/field-masks.
      {Tesla.Middleware.Query, [fields: "sheets.data(rowData(values(effectiveValue)))"]},
      {Tesla.Middleware.JSON, engine_opts: [keys: :atoms]}
    ]

    final_middlewares =
      Enum.reduce(opts, base_middlewares, fn option, acc ->
        case option do
          {:key, key} ->
            [{Tesla.Middleware.Query, [key: key]} | acc]

          {:range, range} ->
            [{Tesla.Middleware.Query, [ranges: range]} | acc]

          {:oauth_token, oauth_token} ->
            [{Tesla.Middleware.BearerAuth, token: oauth_token} | acc]

          _ ->
            acc
        end
      end)

    response =
      final_middlewares
      |> Tesla.client(Tesla.Adapter.Hackney)
      |> Tesla.request(method: :get)

    case response do
      {:ok, %Tesla.Env{body: body, status: status}} ->
        case status do
          200 ->
            {:ok, body}

          _ ->
            case body do
              %{error: %{message: error_message}} ->
                {:error, error_message}

              _ ->
                {:error, :unhandled_exception}
            end
        end

      {:error, _} ->
        {:error, :unhandled_exception}
    end
  end
end
