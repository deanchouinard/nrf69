defmodule NRF69.NReceiver do
  @moduledoc """
  Sample receiver process that will log
  all received packets via Elixir's Logger.

  Will automatically ack packets
  """

  use GenServer
  require Logger

  def hello() do
    IO.inspect("there")
  end

  def start() do
    opts = [reset_pin: 22, ss_pin: 24, irq_pin: 15, spi_bus_name: "spidev0.0",
      encrypt_key: "sampleEncryptKey", node_id: 1, network_id: 100, frequency: 915, auto_ack?: false]

      start_link(opts)

  end
  @doc "args are passed directly to RF69. opts are GenServer opts"
  def start_link(args, opts \\ []) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  @impl GenServer
  def init(args) do
    {:ok, pid} = RF69.start_link(args)
    # Process.send_after(self(), :test_packet, 1500)
    # if the rf69 server is NOT auto_acking,
    # this process should do the acking.
    # this is just an example. If your implementation
    # needs support for manual acking, you should not
    # do it this way.
    if args[:auto_ack?] == false do
      {:ok, %{rf69: pid, auto_ack?: true}}
    else
      {:ok, %{rf69: pid, auto_ack?: false}}
    end
  end

  @impl GenServer
  def handle_info(:hello, state) do
    IO.puts("hello")
    IO.inspect(state.rf69)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:test_packet, state) do
    RF69.send(state.rf69, 2, false, "abc")
    {:noreply, state}
  end

  def handle_info(%RF69.Packet{} = packet, state) do
    # check if this process is responsible for acking.
    # and if the packet requests an ack
    if state.auto_ack? && packet.ack_requested? do
      Logger.debug("Ack")
      RF69.ack(state.rf69, packet)
    end

    Logger.debug("packet received: #{inspect(packet, pretty: true)}")
    IO.inspect packet
    {:noreply, state}
  end
end
