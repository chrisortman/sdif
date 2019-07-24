defmodule Sdif.EntryFolder do
  def load(directory) do
    is_sd3 = fn f ->
      String.downcase(f) |> String.ends_with?(".sd3")
    end

    directory
    |> Path.expand
    |> File.ls!
    |> Enum.filter(is_sd3)
    |> Enum.map( &(Path.join([directory, &1])) )
    |> Enum.flat_map(&Sdif.EntryFile.load/1)
  end
end
