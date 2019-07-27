defmodule Sdif.EntryFile do
  @file_name_regex ~r/(?<team>[[:alnum:]]+)[_-](?<order>[[:digit:]]+)\.[zZ][iI][pP]/

  def load(file_path) do
    file_path
    |> Path.expand()
    |> File.stream!()
    |> Enum.map(&Sdif.parse/1)
  end

  @doc """
  Parse File Name

  ## Examples

      iex> Sdif.EntryFile.parse_file_name("IAVAC_1.ZIP")
      %{:file_name => "IAVAC_1.ZIP", :order => 1, :team => "iavac"}

  """
  def parse_file_name(file_name) do
    captures = Regex.named_captures(@file_name_regex, file_name)

    %{
      file_name: file_name,
      order: String.to_integer(captures["order"]),
      team: String.downcase(captures["team"])
    }
  end

  @doc """
  Select Newest files
  Because you might get multiple entries, this will
  pick the neweset files

  ## Examples

  iex> Sdif.EntryFile.select_newest([%{
  ...>  team: "A", order: 1
  ...> }, %{
  ...>  team: "B", order: 1
  ...> }, %{
  ...>  team: "A", order: 2
  ...> }])
  [%{team: "A", order: 2,},%{team: "B", order: 1}]

  """
  def select_newest(files) do
    files
    |> Enum.group_by(fn f -> f[:team] end)
    |> Enum.map(fn {team, files} ->
      Enum.max_by(files, fn x -> x[:order] end)
    end)
  end

  def extract(src_directory, file_name, to_directory) do
    file_name_erl =
      [src_directory, file_name]
      |> Path.join()
      |> String.to_charlist()

    to_dir_erl =
      to_directory
      |> String.to_charlist()

    {:ok, extracted_files} = :zip.unzip(file_name_erl, [{:cwd, to_dir_erl}])
    Enum.map(extracted_files, &List.to_string/1)
  end
end
