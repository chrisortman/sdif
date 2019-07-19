defmodule SdifTest do
  use ExUnit.Case
  doctest Sdif

  test "reads file description record" do
    sample =
"""
A01V3      01Meet Entries                  TeamUnify, LLC      2.0       Coach, Some         3191112222  05282019

"""
    assert Sdif.parse(sample) == {:file_description, [org: "1", sdif_version: "V3", file_code: "01", fu1: "Meet Entries", software_name: "TeamUnify, LLC", software_version: "2.0", contact_name: "Coach, Some", contact_phone: "3191112222", file_date: ~D[2019-05-28]]}

    Enum.each( (1..3), fn line ->
      sample2 = sample_line(line)
      assert roundtrip(sample2) == sample2
    end)

  end

  def roundtrip(line) do
    Sdif.parse(line) |> Sdif.print
  end

  def sample_line(num) do
    stream = File.stream!("test/sample.sd3")
    [line] = 
      stream
      |> Enum.drop(num-1)
      |> Enum.take(1)

    line
  end
end
