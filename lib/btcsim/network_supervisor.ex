defmodule Bitcoin.NetworkSupervisor do
  use DynamicSupervisor
  require Logger

  @me NetworkSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :no_args, name: @me)
  end

  def init(:no_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add_node({genblock, identifier}) do
    # Logger.debug "#{identifier}}"
    {:ok, pid} = DynamicSupervisor.start_child(@me, {Bitcoin.Node,{genblock, identifier}})
    pid
  end

  def add_fnode({genblock, identifier}) do
    # Logger.debug "#{identifier}}"
    {:ok, pid} = DynamicSupervisor.start_child(@me, {Bitcoin.FullNode,{genblock, identifier}})
    pid
  end

  def add_miner() do
    # Logger.debug "New node created"
    {:ok, pid} = DynamicSupervisor.start_child(@me, Bitcoin.Miner)
    pid
  end
end
