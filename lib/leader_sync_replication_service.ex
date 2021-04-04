defmodule Transactions.LeaderSyncReplicationService do
  use GenServer
  require Logger

  alias Transactions.LeaderSyncReplication

  @moduledoc false

  @spec start_link(LeaderSyncReplication.Config.t()) :: GenServer.on_start()
  def start_link(config) do
    GenServer.start_link(__MODULE__, config)
  end

  @impl GenServer
  def init(config) do
    case LeaderSyncReplication.start_node(config) do
      {:ok, _role} ->
        {:ok, :state}

      {:error, :already_taken_on_this_node} ->
        Logger.warn("Already started on this node")
        {:stop, :normal}

      {:error, :no_quorum} ->
        Logger.warn("No quorum")
        {:stop, :normal}

      {:error, :all_roles_already_exists} ->
        Logger.info("All nodes already exists")
        {:stop, :normal}
    end
  end

  @impl GenServer
  def handle_call({:write, _value}, _from, state) do
    {:reply, :ok, state}
  end
end
