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

  @const_to_kind %{
    "A0" => :file_description,
    "B1" => :meet,
    "B2" => :meet_host,
    "C1" => :team_id
  }

  def parse(<<const::binary-size(2), rest::binary>>) do
    Map.get(@const_to_kind, const, :unknown) |> parse(rest)
  end
  def print({kind, items}) do
    Enum.find(@const_to_kind, fn {k,v} -> v == kind end) |> elem(0) |> print(kind, items)
  end
  # def parse(<<"A0", line::binary>>), do: parse(:file_description, line)
  # def print({:file_description,items}), do: print("A0",:file_description, items)
  #
  # def parse(<<"B1", line::binary>>), do: parse(:meet, line)
  # def print({:meet, items}), do: print("B1",:meet, items)
  #
  # def parse(<<"B2", line::binary>>), do: parse(:meet_host, line)
  # def print({:meet_host, items}), do: print("B2",:meet_host, items)
  #
  # def parse(<<"C1", line::binary>>), do: parse(:team_id, line)
  # def print({:team_id, items}), do: print("C1",:team_id, items)

  def parse(other) when is_binary(other) do
    {:unknown,other}
  end

  def print({:unknown, line}) do
    line
  end

  defp parse(kind, line) do

    fields = field_list(kind)

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
    {kind, Enum.reverse(items)}
  end

  defp print(const, kind, items) do
    fields =
      field_list(kind)
      |> Enum.map(fn

        {f, :future, length} -> Keyword.get(items,f) |> String.pad_trailing(length)
        {f, :date, 8} ->
          d = Keyword.get(items,f)
          month = Integer.to_string(d.month) |> String.pad_leading(2,"0")
          day = Integer.to_string(d.day) |> String.pad_leading(2,"0")
          year = Integer.to_string(d.year)
          month <> day <> year
        {f,:integer, length} -> Keyword.get(items,f) |> String.pad_leading(length)
        {f,_, length} -> Keyword.get(items,f) |> String.pad_trailing(length)

      end) |> Enum.join

    const <> fields <> "\n"
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

  defp field_list(:meet) do
    [
      {:org, :code, 1},
      {:fu1, :future, 8},
      {:meet_name, :alpha, 30},
      {:meet_addr_1, :alpha, 22},
      {:meet_addr_2, :alpha, 22},
      {:meet_city, :alpha, 20},
      {:meet_state, :usps, 2},
      {:meet_zip, :alpha, 10},
      {:country_code, :code, 3},
      {:meet_code, :code, 1},
      {:meet_start, :date, 8},
      {:meet_end, :date, 8},
      {:altitude, :integer, 4},
      {:fu2, :future, 8},
      {:course_code, :code, 1},
      {:fu3, :future, 10}
    ]
  end

  defp field_list(:team_id) do
    [
      {:org, :code, 1},
      {:fu1, :future, 8},
      {:team_code, :code, 6},
      {:full_team_name, :alpha, 30},
      {:abbr_team_name, :alpha, 16},
      {:team_addr_1, :alpha, 22},
      {:team_addr_2, :alpha, 22},
      {:team_city, :alpha, 20},
      {:team_state, :usps, 2},
      {:team_zip, :alpha, 10},
      {:country_code, :code, 3},
      {:region_code, :code, 1},
      {:fu2, :future, 6},
      {:opt_fifth_char, :alpha, 1},
      {:fu3, :future, 10}
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
