defmodule Sdif do
  @moduledoc """
  Documentation for Sdif.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Sdif.hello()
      :world

  """
  def hello do
    :world
  end

  def parse(<<"A0", line::binary>>) do

    <<
      org::binary-size(1),
      v::binary-size(8),
      file_code::binary-size(2),
      fu1 ::binary-size(30),
      software_name::binary-size(20),
      software_version::binary-size(10),
      contact_name::binary-size(20),
      contact_phone::binary-size(12),
      file_date::binary-size(8),
      _ :: binary>> = line

    {:file_description, [
      org: org,
      sdif_version: String.trim_trailing(v),
      file_code: file_code,
      software_name: String.trim_trailing(software_name),
      software_version: String.trim_trailing(software_version),
      contact_name: String.trim_trailing(contact_name),
      contact_phone: String.trim_trailing(contact_phone),
      file_date: parse_date(file_date),
      fu1: fu1
    ]}
  end

  def parse(<<"B1", line::binary>>) do
    <<
      org::binary-size(1),
      _ :: binary-size(8),
      meet_name :: binary-size(30),
      meet_add_1 :: binary-size(22),
      meet_add_2 :: binary-size(22),
      meet_city :: binary-size(20),
      meet_state :: binary-size(2),
      meet_zip :: binary-size(10),
      country_code :: binary-size(3),
      meet_code :: binary-size(1),
      meet_start :: binary-size(8),
      meet_end :: binary-size(8),
      altitude :: binary-size(4),
      _ :: binary-size(8),
      course_code :: binary-size(1),
      _ :: binary >> = line
    {:meet_record, []}
  end


  def print({:file_description, items}) do
    fields = [
      :org,
      {:sdif_version, 8},
      :file_code,
      {:fu1, 30},
      {:software_name, 20},
      {:software_version, 10},
      {:contact_name, 20},
      {:contact_phone, 12},
      {:file_date, :date},
      {:blank, 42},
      {:blank, 2},
      {:blank, 3}
    ] |> Enum.map(fn

      f when is_atom(f) -> Keyword.get(items,f)
      {:blank, pad} -> String.pad_trailing("",pad)
      {f, :date} -> 
        d = Keyword.get(items,f)
        month = Integer.to_string(d.month) |> String.pad_leading(2,"0")
        day = Integer.to_string(d.day) |> String.pad_leading(2,"0")
        year = Integer.to_string(d.year)
        month <> day <> year
      {f,pad} -> Keyword.get(items,f) |> String.pad_trailing(pad)

    end) |> Enum.join

    "A0" <> fields <> "\n\n"
  end

  defp parse_date(str) do

    <<
      month::binary-size(2),
      day::binary-size(2),
      year::binary-size(4)
    >> = str

    [year,month,day] =
      [year,month,day]
      |> Enum.map(&String.to_integer/1)

    {:ok, d} = Date.new(year,month,day)
    d
  end
end
