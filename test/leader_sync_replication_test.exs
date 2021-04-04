defmodule Transactions.LeaderSyncReplicationTest do
  use ExUnit.Case
  alias Transactions.{ClusterRoles, LeaderSyncReplication, Quorum}

  import Hammox

  defmock(QuorumMock, for: Quorum)
  defmock(ClusterRolesMock, for: ClusterRoles)

  @leader_role ClusterRoles.leader()
  @sync_replica_role ClusterRoles.sync_replica()
  @async_replica_role ClusterRoles.async_replica()

  describe "#start_node when have_quorum returns true" do
    setup do
      when_have_quorum_returns(true)
    end

    test "returns :already_taken_on_this_node when trying to run twice" do
      ClusterRolesMock
      |> stub(:register, fn :cluster_roles_mock, _role, _pid -> :ok end)

      assert {:ok, _role_name} = LeaderSyncReplication.start_node(config())
      assert {:error, :already_taken_on_this_node} = LeaderSyncReplication.start_node(config())
    end

    test "registers as leader" do
      ClusterRolesMock
      |> expect(:register, fn :cluster_roles_mock, @leader_role, _pid -> :ok end)

      assert {:ok, @leader_role} = LeaderSyncReplication.start_node(config())
    end

    test "registers as sync_replica" do
      ClusterRolesMock
      |> expect(:register, fn :cluster_roles_mock, @leader_role, _pid -> {:error, :role_already_exists} end)
      |> expect(:register, fn :cluster_roles_mock, @sync_replica_role, _pid -> :ok end)

      assert {:ok, @sync_replica_role} = LeaderSyncReplication.start_node(config())
    end

    test "registers as async_replica" do
      ClusterRolesMock
      |> expect(:register, fn :cluster_roles_mock, @leader_role, _pid -> {:error, :role_already_exists} end)
      |> expect(:register, fn :cluster_roles_mock, @sync_replica_role, _pid -> {:error, :role_already_exists} end)
      |> expect(:register, fn :cluster_roles_mock, @async_replica_role, _pid -> :ok end)

      assert {:ok, :async_replica} = LeaderSyncReplication.start_node(config())
    end
  end

  describe "#start_node when have_quorum returns false" do
    setup do
      when_have_quorum_returns(false)
    end

    test "returns :no_quorum when have_quorum? returns false" do
      ClusterRolesMock
      |> stub(:register, fn :cluster_roles_mock, _role, _pid -> :ok end)

      assert {:error, :no_quorum} = LeaderSyncReplication.start_node(config())
    end
  end

  defp config do
    %LeaderSyncReplication.Config{
      nodes: [:n1, :n2, :n3],
      quorum: Quorum.new(QuorumMock, :quorum_mock),
      roles_registry: ClusterRoles.new(ClusterRolesMock, :cluster_roles_mock)
    }
  end

  defp when_have_quorum_returns(value) do
    QuorumMock
    |> stub(:have_quorum?, fn :quorum_mock, _cluster_size -> value end)

    :ok
  end
end
