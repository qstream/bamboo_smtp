defmodule Bamboo.SmtpConnectionStore do
  require Logger
  use GenServer

  # Start the GenServer with an empty state
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  # Initialize state
  def init(_) do
    {:ok, %{}}
  end

  # API to get a connection from the store (create new if necessary)
  def get_connection(config) do
    GenServer.call(__MODULE__, {:get_connection, config})
  end

  # API to store a connection in the store
  def evict_connection(config) do
    GenServer.call(__MODULE__, {:evict_connection, config})
  end

  # Handle getting a connection
  def handle_call({:get_connection, config}, _from, state) do

    relay = Keyword.get(config, :relay, 25)
    port  = Keyword.get(config, :port)
    case Map.get(state, {relay, port}) do
      nil ->
        # No connection found, create a new one
        new_connection = create_smtp_connection(config)
        {:reply, new_connection, Map.put(state, {relay, port}, new_connection)}
      connection ->
        # Return existing connectionx
        {:reply, connection, state}
    end
  end

  # Handle storing a connection
  def handle_call({:evict_connection, config}, _from, state) do
    relay = Keyword.get(config, :relay, 25)
    port  = Keyword.get(config, :port)
    Logger.info("Removing old connection")
    new_state = Map.delete(state, {relay, port})
    new_connection = create_smtp_connection(config)
    {:reply, new_connection, Map.put(new_state, {relay, port}, new_connection)}
  end

  # Function to create a new SMTP connection (customize as needed)
  defp create_smtp_connection(config) do
    Logger.info("Getting new connection")
    {:ok, pid} = :gen_smtp_client.open(config)
    pid
  end
end
