defmodule BtcsimWeb.BtcChannel do
  use Phoenix.Channel

  def join("btc_update:*", _message, socket) do
    {:ok, socket}
  end

  #handle_in will be for messages coming from browser to the phoenix server, currently not needed

  def broadcast_non(n) do
    BtcsimWeb.Endpoint.broadcast("btc_update:*","no_of_nodes",n)
  end

  def broadcast_notx(%{notx: value}) do
    BtcsimWeb.Endpoint.broadcast("btc_update:*","no_of_tx",%{notx: value})
  end

  def broadcast_aotx(%{aotx: value}) do
    BtcsimWeb.Endpoint.broadcast("btc_update:*","amt_of_tx",%{aotx: value})
  end

  def broadcast_aobtc(%{aobtc: value}) do
    BtcsimWeb.Endpoint.broadcast("btc_update:*","amt_of_btc",%{aobtc: value})
  end

  def broadcast_aoblck(%{amt_blck: value, y: yvalue}) do
    BtcsimWeb.Endpoint.broadcast("btc_update:*","amt_per_block",%{amt_blck: value, y: yvalue})
  end

  def broadcast_txblck(%{tx_blck: value, x: xvalue}) do
    BtcsimWeb.Endpoint.broadcast("btc_update:*","tx_per_block",%{tx_blck: value, x: xvalue})
  end

  def broadcast_tran({from,to,amount}) do
    timedate = DateTime.utc_now() |> DateTime.to_string()
    html = Phoenix.View.render_to_string(BtcsimWeb.PageView, "transrow.html", [time_now: timedate,from: from, to: to, amount: amount])
    BtcsimWeb.Endpoint.broadcast("btc_update:*", "new_tran", %{html: html})
  end

end
