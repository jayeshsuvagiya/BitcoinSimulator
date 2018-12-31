defmodule Bitcoin.Miner do


  @moduledoc false



  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__,:no_args)
  end

  def init(:no_args) do
    {:ok, {false,nil,nil,nil}}
  end

  def handle_call(:get_status, _f, {mine?, block, parent_node,name}) do

    {:reply,mine?, {mine?, block, parent_node,name}}
  end

  def handle_call(:stop, _parent_node, {mine?, block, parent_node,name}) do
    #IO.inspect("STOP MINING - #{name}}")
    {:reply, {:ok,block}, {false, block, parent_node,name}}
  end



  def handle_call({:start_mine, block,name}, parent_node, state) do
    #IO.inspect("Start mine - #{name} block tx size = #{Enum.count(block.txns)}")
   # IO.inspect(block)
    Process.send_after(self(), :do_mine, 50)
    {:reply, :ok, {true, block, parent_node,name}}
  end

  def handle_info(:do_mine, {mine?, block, parent_node,name})   do
    if mine? do
      block = Bitcoin.Block.calchash(block)
      #IO.inspect("Mining Nonce = #{block.nonce}")
      if Bitcoin.Block.checkhash(block) do
        #notify mined
        #IO.inspect("Mining completed - #{name}")
        GenServer.cast(globalcall(name),{:block_mined, block})
      else
        Process.send_after(self(), :do_mine, 0)
      end
    end
    {:noreply, {mine?, %{block | nonce: block.nonce + 1}, parent_node,name}}
  end

  def globalcall(a) do
    {:global,a}
  end
end