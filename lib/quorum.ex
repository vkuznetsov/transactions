defmodule Transactions.Quorum do
  @moduledoc false

  @type t :: {:quorum_impl, module(), instance :: any()}

  @callback have_quorum?(instance :: any(), cluster_size :: pos_integer()) :: boolean()

  @spec have_quorum?(t, cluster_size :: pos_integer()) :: boolean()
  def have_quorum?({:quorum_impl, impl, instance}, cluster_size), do: impl.have_quorum?(instance, cluster_size)
end
