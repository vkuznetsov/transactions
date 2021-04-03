defmodule Transactions.LeaderSyncReplication do
  alias Transactions.{ClusterRoles, Quorum}

  @moduledoc false

  defmodule Config do
    use TypedStruct
    @moduledoc false

    typedstruct enforce: true do
      field :nodes, list(node)
      field :quorum, Quorum.t()
      field :roles_registry, ClusterRoles.t()
      field :node_wait_timeout_ms, timeout, default: 20
      field :retry_interval_ms, timeout, default: 5
    end
  end

  @spec send(Config.t(), pos_integer(), any()) :: :ok | {:error, :timeout}
  def send(%Config{} = config, _lsn, _value) do
    case [
      wait_for(ClusterRoles.leader(), config),
      wait_for(ClusterRoles.sync_replica(), config),
      wait_for(ClusterRoles.async_replica(), config)
    ] do
      [{:ok, _leader_pid}, {:ok, _sync_replica_pid}, {:ok, _async_replica_pid}] ->
        # with {:ok, leader_tx} <- prepare_leader(leader_pid, lsn, value),
        #      {:ok, replica_tx} <- prepare_replica(replica_pid, lsn, value),
        #      :ok <- commit_leader(leader_pid, leader_tx),
        #      :ok <- commit_replica(replica_pid, replica_tx) do
        #   send_to_async_replica()
        # end
        :ok

      [{:error, :timeout}, _, _] ->
        {:error, :no_leader}

      [_, {:error, :timeout}, _] ->
        {:error, :no_sync_replica}

      [_, _, {:error, :timeout}] ->
        {:error, :no_async_replica}
    end
  end

  @spec start_node(Config.t()) ::
          {:ok, ClusterRoles.role_name()}
          | {:error, :no_quorum | :all_roles_already_exists | :already_taken_on_this_node}
  def start_node(%Config{} = config) do
    with :ok <- assert_single_on_this_node(),
         {:error, :role_already_exists} <- register(config, ClusterRoles.leader()),
         {:error, :role_already_exists} <- register(config, ClusterRoles.sync_replica()),
         {:error, :role_already_exists} <- register(config, ClusterRoles.async_replica()) do
      {:error, :all_roles_already_exists}
    else
      {:ok, role_name} -> if have_quorum?(config), do: {:ok, role_name}, else: {:error, :no_quorum}
      {:error, :already_taken_on_this_node} -> {:error, :already_taken_on_this_node}
    end
  end

  @spec wait_for(ClusterRoles.role_name(), Config.t(), integer) :: {:ok, pid()} | {:error, :timeout}
  defp wait_for(role_name, %Config{} = config, start_time \\ System.monotonic_time()) do
    case ClusterRoles.get(config.roles_registry, role_name) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, :notfound} ->
        if System.monotonic_time() > start_time + config.node_wait_timeout_ms do
          {:error, :timeout}
        else
          Process.sleep(config.retry_interval_ms)
          wait_for(role_name, config, start_time)
        end
    end
  end

  @spec register(Config.t(), ClusterRoles.role_name()) ::
          {:ok, ClusterRoles.role_name()} | {:error, :role_already_exists}
  defp register(%Config{roles_registry: registry}, role_name) do
    case ClusterRoles.register(registry, role_name, self()) do
      :ok -> {:ok, role_name}
      {:error, :role_already_exists} -> {:error, :role_already_exists}
    end
  end

  @spec have_quorum?(Config.t()) :: boolean()
  defp have_quorum?(%Config{nodes: nodes, quorum: quorum}) do
    Quorum.have_quorum?(quorum, Enum.count(nodes))
  end

  @spec assert_single_on_this_node :: :ok | {:error, :already_taken_on_this_node}
  defp assert_single_on_this_node do
    true = Process.register(self(), __MODULE__)
    :ok
  rescue
    ArgumentError -> {:error, :already_taken_on_this_node}
  end
end
