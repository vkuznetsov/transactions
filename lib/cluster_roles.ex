defmodule Transactions.ClusterRoles do
  @moduledoc false

  @type instance :: any()
  @type role_name :: :leader | :sync_replica | :async_replica
  @type t :: {:cluster_role_registration, module(), instance}

  @callback register(instance(), role_name, pid()) :: :ok | {:error, :role_already_exists}
  @callback get(instance(), role_name) :: {:ok, pid()} | {:error, :notfound}

  @spec register(t, role_name, pid()) :: :ok | {:error, :role_already_exists}
  def register({:cluster_role_registration, impl, instance}, role_name, pid) do
    impl.register(instance, role_name, pid)
  end

  @spec get(t, role_name) :: {:ok, pid()} | {:error, :notfound}
  def get({:cluster_role_registration, impl, instance}, role_name) do
    impl.get(instance, role_name)
  end

  @spec leader :: :leader
  def leader, do: :leader

  @spec sync_replica :: :sync_replica
  def sync_replica, do: :sync_replica

  @spec async_replica :: :async_replica
  def async_replica, do: :async_replica
end
