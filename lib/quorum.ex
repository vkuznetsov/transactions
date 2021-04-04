defmodule Transactions.Quorum do
  @moduledoc false

  @type instance :: any()
  @type t :: {:quorum_impl, module(), instance :: any()}

  @callback have_quorum?(instance :: any(), cluster_size :: pos_integer()) :: boolean()

  @spec new(module(), instance()) :: t
  def new(module, instance), do: {:quorum_impl, module, instance}

  @spec have_quorum?(t, cluster_size :: pos_integer()) :: boolean()
  def have_quorum?({:quorum_impl, impl, instance}, cluster_size), do: impl.have_quorum?(instance, cluster_size)
end
