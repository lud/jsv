defmodule JSV.Resolver.Cache do
  use GenServer

  @gen_opts ~w(name timeout debug spawn_opt hibernate_after)a

  def start_link(opts) do
    :ok = validate_opts!(opts)
    name = Keyword.fetch!(opts, :name)
    {gen_opts, opts} = Keyword.split(opts, @gen_opts)
    GenServer.start_link(__MODULE__, [{:name, name} | opts], gen_opts)
  end

  IO.warn("TODO use nimbleoptions")

  defp validate_opts!(opts) do
    case Keyword.fetch(opts, :name) do
      {:ok, atom} when is_atom(atom) -> {:ok, opts}
      {:ok, other} -> raise ArgumentError, "invalid :name option, got: #{other}"
      :error -> raise ArgumentError, ":name option is required"
    end

    :ok
  end

  def get_or_generate(name, key, fun) do
    with :error <- lookup(name, key) do
      maybe_generate(name, key, fun)
    end
  end

  def maybe_generate(name, key, fun) do
    case GenServer.call(name, {:maybe_generate, key, fun}) do
      {:ok, :generated} -> lookup!(name, key)
      {:error, _} = err -> err
    end
  end

  defp lookup(name, key) do
    case :ets.lookup(name, key) do
      [{^key, value}] -> {:ok, value}
      [] -> :error
    end
  end

  defp lookup!(name, key) do
    with :error <- lookup(name, key) do
      raise "could not retrieve cache key #{inspect(key)}"
    end
  end

  @impl true
  def init(opts) do
    name = Keyword.fetch!(opts, :name)
    _tab = :ets.new(name, [:named_table, :public, read_concurrency: true])
    {:ok, task_sup} = Task.Supervisor.start_link()
    {:ok, %{name: name, task_sup: task_sup, pending: %{}}}
  end

  @impl true
  def handle_call({:maybe_generate, key, fun}, from, state) do
    {:noreply, start_or_add_client(state, key, fun, from)}
  end

  @impl true
  def handle_info({ref, result}, state) when is_reference(ref) do
    Process.demonitor(ref, [:flush])

    state =
      case result do
        {:ok, key} -> finalize_generation(state, key)
        {:error, key, reason} -> error_and_rotate_clients(state, key, reason)
      end

    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, _pid, reason}, state) when is_reference(ref) do
    state =
      case Enum.find_value(state.pending, fn {key, {^ref, _, _}} -> key end) do
        # Should not happen
        nil -> state
        key -> error_and_rotate_clients(state, key, reason)
      end

    {:noreply, state}
  end

  defp start_or_add_client(state, key, fun, from) do
    pending =
      case state.pending do
        %{^key => {task, fun_from, clients}} = pending ->
          Map.put(pending, key, {task, fun_from, [{from, fun} | clients]})

        pending ->
          task_ref = start_task(state, key, fun)
          Map.put(pending, key, {task_ref, from, []})
      end

    %{state | pending: pending}
  end

  defp start_task(state, key, fun) do
    %{task_sup: task_sup, name: name} = state
    %Task{ref: ref} = Task.Supervisor.async_nolink(task_sup, fn -> produce(name, key, fun) end)
    ref
  end

  defp produce(name, key, fun) do
    case fun.() do
      {:ok, value} ->
        true = :ets.insert(name, {key, value})
        {:ok, key}

      {:error, reason} ->
        {:error, key, reason}

      other ->
        raise "bad return value from cache fun function: #{inspect(other)}"
    end
  end

  defp finalize_generation(state, key) do
    {{_, fun_from, clients}, pending} = Map.pop!(state.pending, key)
    send_success(fun_from, clients)
    %{state | pending: pending}
  end

  defp error_and_rotate_clients(state, key, reason) do
    {{_, fun_from, clients}, pending} = Map.pop!(state.pending, key)
    send_error(fun_from, reason)

    pending =
      case clients do
        [] ->
          pending

        [{new_from, new_fun} | rest_clients] ->
          task_ref = start_task(state, key, new_fun)
          Map.put(pending, key, {task_ref, new_from, rest_clients})
      end

    %{state | pending: pending}
  end

  defp send_success(fun_from, clients) do
    GenServer.reply(fun_from, {:ok, :generated})
    Enum.each(clients, fn {from, _} -> GenServer.reply(from, {:ok, :generated}) end)
  end

  defp send_error(fun_from, reason) do
    GenServer.reply(fun_from, {:error, reason})
  end
end
