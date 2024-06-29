defmodule Sheetex do
  alias GoogleApi.Sheets
  alias GoogleApi.Sheets.V4.Model

  @doc """
  Fetch the contents of a Google Sheet.
  """
  def fetch_sheet(spreadsheet_id, opts) do
    additional_opts = [
      # Apply field mask to only get the value of each cell in the spreadsheet/range.
      # see https://developers.google.com/sheets/api/guides/field-masks
      {:fields, "sheets.data(rowData(values(effectiveValue)))"}
    ]

    case Sheets.V4.Api.Spreadsheets.sheets_spreadsheets_get(
           Sheets.V4.Connection.new(),
           spreadsheet_id,
           opts ++ additional_opts
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

  def fetch_sheet!(spreadsheet_id, opts) do
    {:ok, result} = fetch_sheet(spreadsheet_id, opts)

    result
  end

  @doc """
  Transform the result (a list of rows) into a list of maps – using the first row as the header row.
  """
  @spec to_kv(list()) :: list(map())
  def to_kv(result) when is_list(result) do
    [header_row | rows] = result

    Enum.map(rows, fn row ->
      Enum.zip(header_row, row) |> Map.new()
    end)
  end
end
