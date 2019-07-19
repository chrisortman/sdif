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

    # <<
    #   org::binary-size(1),
    #   v::binary-size(8),
    #   file_code::binary-size(2),
    #   fu1 ::binary-size(30),
    #   software_name::binary-size(20),
    #   software_version::binary-size(10),
    #   contact_name::binary-size(20),
    #   contact_phone::binary-size(12),
    #   file_date::binary-size(8),
    #   _ :: binary>> = line

    fields = field_list(:file_description)

    {line, items} = Enum.reduce(fields, {line,[]}, fn f, {rest,parsed} ->
      {f_key, f_type, f_length} = f
      case rest do
        <<f_val::binary-size(f_length),unparsed::binary>> ->

          final_val = case f_type do
            :date -> parse_date(f_val)
            _ -> String.trim(f_val)
          end
          items = Keyword.put(parsed, f_key, final_val)
          {unparsed, items}
        _ ->
          IO.puts "Failed match"
          IO.inspect f
          IO.inspect rest
          IO.puts "-----------------\n"
          {"", parsed}
      end
    end)
    {:file_description, Enum.reverse(items)}
    # {:file_description, [
    #   org: org,
    #   sdif_version: String.trim_trailing(v),
    #   file_code: file_code,
    #   software_name: String.trim_trailing(software_name),
    #   software_version: String.trim_trailing(software_version),
    #   contact_name: String.trim_trailing(contact_name),
    #   contact_phone: String.trim_trailing(contact_phone),
    #   file_date: parse_date(file_date),
    #   fu1: fu1
    # ]}
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

  def parse(other) when is_binary(other) do
    {:unknown,other}
  end

  def print({:file_description, items}) do
    fields =
      field_list(:file_description)
      |> Enum.map(fn

        {f, :future, length} -> Keyword.get(items,f) |> String.pad_trailing(length)
        {f, :date, 8} ->
          d = Keyword.get(items,f)
          month = Integer.to_string(d.month) |> String.pad_leading(2,"0")
          day = Integer.to_string(d.day) |> String.pad_leading(2,"0")
          year = Integer.to_string(d.year)
          month <> day <> year
        {f,_, length} -> Keyword.get(items,f) |> String.pad_trailing(length)

      end) |> Enum.join

    "A0" <> fields <> "\n"
  end

  def print({:unknown, line}) do
    line
  end

  defp field_list(:file_description) do
    [
      {:org, :code, 1},
      {:sdif_version, :alpha, 8},
      {:file_code, :code, 2},
      {:fu1, :future, 30},
      {:software_name, :alpha, 20},
      {:software_version, :alpha, 10},
      {:contact_name, :alpha, 20},
      {:contact_phone, :phone, 12},
      {:file_date, :date, 8},
      {:fu2, :future, 42},
      {:submitted_by_lsc, :alpha, 2},
      {:fu3,:future, 3}
    ]

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
