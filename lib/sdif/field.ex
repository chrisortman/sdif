defmodule Sdif.Field do

  def parse({kind,fields}, line) do

    {line, items} = Enum.reduce(fields, {line,[]}, fn f, {rest,parsed} ->
      {f_key, f_type, f_length} = f
      case rest do
        <<f_val::binary-size(f_length),unparsed::binary>> ->

          final_val = case f_type do
            :date ->
              if f_val != "        " do
                parse_date(f_val)
              else
                ""
              end
            _ -> String.trim(f_val)
          end
          items = put_in(parsed, [f_key], final_val)
          {unparsed, items}
        _ ->
          print_failure(f,rest)
          {"", parsed}
      end
    end)
    {kind, Enum.reverse(items)}
  end

  def parse(other) when is_binary(other) do
    {:unknown,other}
  end

  def print({:unknown, line}) do
    line
  end

  def print(const, {kind,fields}, items) do
      data = Enum.map(fields, fn

        {:event_number, :alpha, 4} ->
          val = items[:event_number]
          case String.length(val) do
            3 -> val <> " "
            2 -> " " <> val <> " "
            _ -> val
          end
        {:swimmer_age_or_class, :alpha, 2} -> String.pad_leading(items[:swimmer_age_or_class],2)
        {f, :future, length} -> items[f] |> String.pad_trailing(length)
        {f, :date, 8} ->
          d = items[f]
          case d do
            %Date{} ->
              month = Integer.to_string(d.month) |> String.pad_leading(2,"0")
              day = Integer.to_string(d.day) |> String.pad_leading(2,"0")
              year = Integer.to_string(d.year)
              month <> day <> year
            "" -> String.pad_trailing("",8)
          end
        {f, :time, length} -> items[f] |> String.pad_leading(length)
        {f,:integer, length} -> items[f] |> String.pad_leading(length)
        {f,:decimal, length} -> items[f] |> String.pad_leading(length)
        {f,_, length} -> items[f] |> String.pad_trailing(length)

      end) |> Enum.join

    record = const <> data
    String.pad_trailing(record,160) <> "\n"
  end

  defp print_failure(f,rest) do
    IO.puts "Failed match"
    IO.inspect f
    IO.inspect rest
    IO.puts "-----------------\n"
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
