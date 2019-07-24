defmodule Sdif do
  alias Sdif.Field

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
    "C1" => :team_id,
    "D0" => :individual_event,
    "D3" => :individual_information,
    "Z0" => :file_terminator
  }

  def parse(<<const::binary-size(2), rest::binary>>) do
    kind =
      @const_to_kind
      |> Access.get(const, :unknown)

    fields = field_list(kind)
    Field.parse({kind, fields}, rest)
  end

  def print({kind, items}) do
    const =
      @const_to_kind
      |> Enum.find(fn {k, v} -> v == kind end)
      |> elem(0)

    fields = field_list(kind)
    Field.print(const, {kind, fields}, items)
  end

  def extract_files(src_directory), do: extract_files(src_directory, src_directory)
  def extract_files(src_directory, to_directory) do
    src_directory
    |> Path.expand
    |> entry_files
    |> Enum.flat_map(fn file ->
      IO.puts "Extract #{file[:file_name]}"
      Sdif.EntryFile.extract(src_directory, file[:file_name], to_directory)
    end)
  end

  def entry_files(directory \\ "/Users/cortman/Documents/SwimMeets/Splash Out Hunger/Meet Entries/Entry Files for MM") do
    {:ok, files} = File.ls(directory)
    zips = Enum.filter(files, fn f ->
      String.upcase(f) |> String.ends_with?(".ZIP")
    end)

    entry_files =
      zips
      |> Enum.map(&Sdif.EntryFile.parse_file_name/1)
      |> Sdif.EntryFile.select_newest

    entry_files
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
      {:fu3, :future, 3}
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

  defp field_list(:individual_event) do
    [
      {:org, :code, 1},
      {:fu1, :future, 8},
      {:swimmer_name, :name, 28},
      {:uss_number, :alpha, 12},
      {:attach_code, :code, 1},
      {:citizen_code, :code, 3},
      {:swimmer_birth_date, :date, 8},
      {:swimmer_age_or_class, :alpha, 2},
      {:sex_code, :code, 1},
      {:event_sex_code, :code, 1},
      {:event_distance, :integer, 4},
      {:stroke_code, :code, 1},
      {:event_number, :alpha, 4},
      {:event_age_code, :code, 4},
      {:date_of_swim, :date, 8},
      {:seed_time, :time, 8},
      {:course_code_1, :code, 1},
      {:prelim_time, :time, 8},
      {:course_code_2, :code, 1},
      {:swim_off_time, :time, 8},
      {:course_code_3, :code, 1},
      {:finals_time, :time, 8},
      {:course_code_4, :code, 1},
      {:prelim_heat_number, :integer, 2},
      {:prelim_lane_number, :integer, 2},
      {:finals_heat_number, :integer, 2},
      {:finals_lane_number, :integer, 2},
      {:prelim_place_ranking, :integer, 3},
      {:finals_place_ranking, :integer, 3},
      {:points_scored_from_finals, :decimal, 4},
      {:event_time_class_code, :code, 2}
    ]
  end

  defp field_list(:individual_information) do
    [
      {:uss_number, :ussnum, 14},
      {:preferred_first_name, :alpha, 15},
      {:ethnicity_code, :code, 2},
      {:junior_high_school, :logical, 1},
      {:senior_high_school, :logical, 1},
      {:ymca_ywca, :logical, 1},
      {:college, :logical, 1},
      {:summer_swim_league, :logical, 1},
      {:masters, :logical, 1},
      {:disabled_sports_organizations, :logical, 1},
      {:water_polo, :logical, 1},
      {:none, :logical, 1},
      {:fu1, :future, 118}
    ]
  end

  defp field_list(:file_terminator) do
    [
      {:org, :code, 1},
      {:fu1, :future, 8},
      {:file_code, :code, 2},
      {:notes, :alpha, 30},
      {:num_b_rec, :integer, 3},
      {:num_diff_meets, :integer, 3},
      {:num_c_rec, :integer, 4},
      {:num_diff_teams, :integer, 4},
      {:num_d_rec, :integer, 6},
      {:num_diff_swimmers, :integer, 6},
      {:num_e_rec, :integer, 5},
      {:num_f_rec, :integer, 6},
      {:num_g_rec, :integer, 6},
      {:batch_number, :integer, 5},
      {:num_new_members, :integer, 2},
      {:garbage, :future, 10}
    ]
  end

  defp field_list(:unknown) do
    []
  end
end
