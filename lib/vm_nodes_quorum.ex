defmodule Transactions.VmNodesQuorum do
  alias Transactions.Quorum

  @moduledoc false
  @behaviour Quorum

  @impl Quorum
  def have_quorum?(_instance, cluster_size) do
    nodes = Node.list()

    accessible_nodes =
      nodes
      |> Task.async_stream(&node_available?/1, ordered: false, max_concurrency: Enum.count(nodes))
      |> Enum.filter(& &1)

    me = 1
    min_quorum_count = trunc(cluster_size / 2) + 1
    Enum.count(accessible_nodes) + me >= min_quorum_count
  end

  @spec node_available?(node()) :: boolean()
  defp node_available?(node) do
    :erpc.call(node, fn -> :available end) == :available
  end
end
