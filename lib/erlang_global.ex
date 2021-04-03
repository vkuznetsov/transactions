defmodule Transactions.ErlangGlobal do
  alias Transactions.ClusterRoles

  @moduledoc false
  @behaviour ClusterRoles

  @impl ClusterRoles
  def get(_instance, role_name) do
    case :global.whereis_name(role_name) do
      :undefined -> {:error, :notfound}
      pid -> {:ok, pid}
    end
  end

  @impl ClusterRoles
  def register(_instance, role_name, pid) do
    case :global.register_name(role_name, pid) do
      :yes -> :ok
      :no -> {:error, :role_already_exists}
    end
  end
end
