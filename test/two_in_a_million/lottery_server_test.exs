defmodule TwoInAMillion.LotteryServerTest do
  use TwoInAMillion.DataCase, async: true

  alias TwoInAMillion.LotteryServer
  alias TwoInAMillion.RandomNumberGeneratorMock
  alias TwoInAMillion.Repo

  import Mox

  def start_server(name, opts \\ []) do
    opts = Keyword.put_new(opts, :max_number, 0)
    opts = Keyword.put(opts, :number_generator, RandomNumberGeneratorMock)

    server_spec = %{
      id: name,
      start: {LotteryServer, :start_link, [opts, [name: name]]}
    }

    server_pid = start_supervised!(server_spec)
    Ecto.Adapters.SQL.Sandbox.allow(Repo, self(), server_pid)
    allow(RandomNumberGeneratorMock, self(), server_pid)
    server_pid
  end

  describe "pick_winners/2" do
    test "returns users with more points than the current threshold", %{test: unique_name} do
      user1 = create_user(points: 10)
      user2 = create_user(points: 20)
      user3 = create_user(points: 30)
      user4 = create_user(points: 40)

      server_pid = start_server(unique_name, max_number: 15)

      assert %{
               users: users,
               timestamp: nil
             } = LotteryServer.pick_winners(5, server_pid)

      assert user2 in users
      assert user3 in users
      assert user4 in users
      refute user1 in users
    end

    test "returns at most the given number of users", %{test: unique_name} do
      create_user(points: 20)
      create_user(points: 30)
      create_user(points: 40)

      server_pid = start_server(unique_name, max_number: 15)

      assert %{
               users: users
             } = LotteryServer.pick_winners(2, server_pid)

      assert length(users) <= 2
    end

    test "returns the timestamp of the previous call", %{test: unique_name} do
      server_pid = start_server(unique_name)

      assert %{timestamp: nil} = LotteryServer.pick_winners(0, server_pid)
      assert %{timestamp: %DateTime{} = timestamp1} = LotteryServer.pick_winners(0, server_pid)
      assert %{timestamp: %DateTime{} = timestamp2} = LotteryServer.pick_winners(0, server_pid)

      assert DateTime.compare(timestamp1, timestamp2) == :lt
    end
  end

  test "regularly updates the points of users", %{test: unique_name} do
    # Initialize with invalid value to guarantee that the points won't accidentally
    # stay the same after the update.
    user1 = create_user(points: -1)
    round_duration = 100
    points_range = Application.fetch_env!(:two_in_a_million, LotteryServer)[:points_range]

    start_server(unique_name, round_duration: round_duration)

    Process.sleep(round_duration + 50)

    updated_user1 = reload_record(user1)
    refute updated_user1.points == user1.points
    assert updated_user1.points in points_range

    user2 = create_user(points: -1)

    Process.sleep(round_duration + 50)

    updated_user2 = reload_record(user2)
    refute updated_user2.points == user2.points
    assert updated_user2.points in points_range
  end
end
