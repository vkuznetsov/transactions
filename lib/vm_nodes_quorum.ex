defmodule Transaction.VmNodesQuorum do
  alias Transactions.Quorum
  alias :erpc, as: Erpc

  @moduledoc false
  @behaviour Quorum

  @impl Quorum
  def have_quorum?(_instance, cluster_size) do
    nodes = Node.list()

    accessible_nodes =
      nodes
      |> Task.async_stream(&Erpc.call(&1, fn -> :ok end), ordered: false, max_concurrency: Enum.count(nodes))
      |> Enum.filter(&match?(:ok, &1))

    me = 1
    min_quorum_count = trunc(cluster_size / 2) + 1
    Enum.count(accessible_nodes) + me >= min_quorum_count
  end
end
