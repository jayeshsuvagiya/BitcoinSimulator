defmodule Bitcoin.BitcoinSimulator do

  use GenServer
  require Logger

  @moduledoc false

  @me BitcoinSimulator

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: @me)
  end

  def init(args) do
    Process.send_after(self(), :kickoff, 15000)
    {:ok, args}
  end

  def handle_info(:kickoff, state)   do

    sk = Bitcoin.Crypto.generate()
    pk = Bitcoin.Crypto.to_public_key(sk)
    pkh = Bitcoin.Crypto.to_public_hash(pk)
    #IO.inspect("Gen Reward  - #{pkh}")
    '''
            sign = Bitcoin.Crypto.sign("hello", sk)
            ver = Bitcoin.Crypto.verify("hello", sign , pk )
            IO.inspect(
              sk
              |> Base.encode16()
            )
            IO.inspect(
              pk
            )
            IO.inspect(sign)
            IO.inspect(ver)



            sk1 = Base.decode16!("2fa30c73b04538e2bd2d5d6988f329439eec4304c7901c20a70548f8f4564cc7", case: :lower);
            pk1 = Bitcoin.Crypto.to_public_key(sk1);
            sign1 = Bitcoin.Crypto.sign("aaa", sk1)
            ver1 = Bitcoin.Crypto.verify("aaa", sign1, pk1)
            IO.inspect(
              sk1
              |> Base.encode16()
            )
            IO.inspect(
              pk1
            )
            IO.inspect(
              sign1
            )
            IO.inspect(ver1)
    '''
    t_in = Bitcoin.Tx_In.new(0, -1, nil, nil)
    tout = Bitcoin.Tx_Out.new(25, pkh)
    reward_tran = Bitcoin.Transaction.new([t_in], [tout])
    reward_tran = Bitcoin.Transaction.calchash(reward_tran)
    genblock = Bitcoin.Block.mine(Bitcoin.Block.genblock([reward_tran]))
    #genblock = Bitcoin.Block.genblock([reward_tran])





    #{:ok, pid} = GenServer.start_link(Bitcoin.Miner, nil)
    #GenServer.call(pid, {:start_mine, Bitcoin.Block.genblock()})
    #Process.sleep(100)
    #GenServer.call(pid, :stop)
    #Process.sleep(100)
    #GenServer.call(pid, {:start_mine, Bitcoin.Block.genblock()})

    ##Generate nodes
    nodes = 1..100
            |> Enum.map(
                 fn x -> Bitcoin.NetworkSupervisor.add_node({genblock, "node_#{x}"})
                 end
               )

    Enum.each(nodes, fn x -> GenServer.call(x, :kick_off) end)

    fnode = Bitcoin.NetworkSupervisor.add_fnode({genblock, "f_node"})
    GenServer.call(fnode, :kick_off)

    #send 25 of gen reward to one of the peer rest to self
    {name, s_addr} = GenServer.call(List.first(nodes), :get_address)
    IO.inspect("Sent to - #{s_addr}")
    out = List.first(reward_tran.tx_out)
    data = "#{reward_tran.hash}#{0}#{out.rpkh}#{s_addr}#{25}}"
    sign = Bitcoin.Crypto.sign(data, sk)
    tin = Bitcoin.Tx_In.new(reward_tran.hash, 0, sign, pk)

    tout = Bitcoin.Tx_Out.new(25, s_addr)
    sout = Bitcoin.Tx_Out.new(25, pkh)
    output_trans = [tout, sout]
    trans = Bitcoin.Transaction.new([tin], output_trans)
    trans = Bitcoin.Transaction.calchash(trans)
    #IO.inspect(nodes)
    #IO.inspect(trans)
    GenServer.cast(self(), {:broad_trans, trans})

    Process.send_after(self(), :broad_non, 500)
    Process.send_after(self(), :check_bal, 10000)
    Process.send_after(self(),{:perform_tran_start,5},1000)
    Process.send_after(self(),{:perform_tran_start,5},2000)
    Process.send_after(self(),{:perform_tran_start,5},4000)
    Process.send_after(self(),{:perform_tran_start,5},5000)
    Process.send_after(self(),{:perform_tran_start,5},5000)
    Process.send_after(self(),{:perform_tran_start,5},5000)
    Process.send_after(self(),{:perform_tran_start,5},5000)
    Process.send_after(self(),{:perform_tran_start,5},6000)
    Process.send_after(self(),{:perform_tran_start,10},7000)
    Process.send_after(self(),{:perform_tran_start,10},8000)
    Process.send_after(self(),{:perform_tran_start,10},9000)
    Process.send_after(self(),{:perform_tran_start,15},10000)
    Process.send_after(self(),{:perform_tran_start,15},11000)
    Process.send_after(self(),{:perform_tran_start,15 },12000)
    Process.send_after(self(),{:perform_tran_start,15 },15000)
    Process.send_after(self(),{:perform_tran_start,30},17000)
    Process.send_after(self(),{:perform_tran_start,30},20000)
    Process.send_after(self(),{:perform_tran_start,30},25000)

    Process.send_after(self(), :perform_tran, 20000)
    #System.halt(0)
    {:noreply, {nodes, fnode}}
  end

  def handle_info(:check_bal, {nodes, fnode}) do
    Enum.each(nodes, fn pid -> GenServer.cast(pid, :check_bal) end)
    #GenServer.cast(List.first(nodes), :check_bal)
    #Process.send_after(self(), :broad_non, 15000)
    {:noreply, {nodes, fnode}}
  end

  def handle_info(:perform_tran, {nodes, fnode}) do
    non_trans = 1..3
    for x <- non_trans  do
      [n1, n2] = Enum.take_random(nodes, 2)
      {sender_name, n2_addr} = GenServer.call(n2, :get_address)
      amount = Enum.random(10..50)
      GenServer.cast(n1, {:perform_trans, n2_addr, amount, sender_name})
    end
    Process.send_after(self(), :perform_tran, Enum.random(1..5000))
    {:noreply, {nodes, fnode}}
  end

  def handle_info({:perform_tran_start,i}, {nodes, fnode}) do
    non_trans = 1..3
    sun_nodes=Enum.take(nodes,i)
    for x <- non_trans  do
      [n1, n2] = Enum.take_random(sun_nodes, 2)
      {sender_name, n2_addr} = GenServer.call(n2, :get_address)
      amount = Enum.random(10..50)
      GenServer.cast(n1, {:perform_trans, n2_addr, amount, sender_name})
    end
    {:noreply, {nodes, fnode}}
  end

  def handle_info(:broad_non, {nodes, fnode}) do
    BtcsimWeb.BtcChannel.broadcast_non(%{non: length(nodes)})
    Process.send_after(self(), :broad_non, 50000)
    {:noreply, {nodes, fnode}}
  end

  def handle_cast({:broad_trans, trans}, {nodes, fnode}) do
    #IO.inspect("Broadcast trans")
    GenServer.cast(fnode, {:rec_trans, trans})
    Enum.each(nodes, fn pid -> GenServer.cast(pid, {:rec_trans, trans}) end)
    {:noreply, {nodes, fnode}}
  end

  def handle_call({:broad_trans, trans},_from, {nodes, fnode}) do
    #IO.inspect("Broadcast trans")
    GenServer.cast(fnode, {:rec_trans, trans})
    Enum.each(nodes, fn pid -> GenServer.cast(pid, {:rec_trans, trans}) end)
    {:reply,:ok, {nodes, fnode}}
  end

  def handle_call({:broad_block, block}, _from, {nodes, fnode}) do
    #IO.inspect("Broadcast block")
    GenServer.cast(fnode, {:rec_block, block})
    Enum.each(nodes, fn pid -> GenServer.cast(pid, {:rec_block, block}) end)
    {:reply, :ok, {nodes, fnode}}
  end
end
