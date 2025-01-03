defmodule JSV.Resolver.CacheTest do
  alias JSV.Resolver.Cache
  use ExUnit.Case, async: true

  test "creates a public ETS table with its name" do
    pid = start_supervised!({Cache, name: :some_name})
    assert pid == Process.whereis(:some_name)
    info = :ets.info(:some_name)
    assert is_list(info)

    assert :public == info[:protection]
    assert true == info[:read_concurrency]
    assert false == info[:write_concurrency]
  end

  test "will not call the generator function twice with concurrent misses" do
    name = :concurrent_check
    _pid = start_supervised!({Cache, name: name})

    # We will call the cache concurrently multiple times but only one generator
    # fun will be called

    parent = self()

    generator = fn ->
      # generator sleeps a bit so we know we are not just calling them serially
      # and thus reading from the ETS table.
      Process.sleep(100)
      send(parent, :generator_called)
      Process.sleep(100)
      {:ok, :returned_value}
    end

    task_1 = Task.async(fn -> Cache.get_or_generate(name, :some_key, generator) end)
    task_2 = Task.async(fn -> Cache.get_or_generate(name, :some_key, generator) end)
    task_3 = Task.async(fn -> Cache.get_or_generate(name, :some_key, generator) end)
    task_4 = Task.async(fn -> Cache.get_or_generate(name, :some_key, generator) end)

    assert {:ok, :returned_value} = Task.await(task_1)
    assert {:ok, :returned_value} = Task.await(task_2)
    assert {:ok, :returned_value} = Task.await(task_3)
    assert {:ok, :returned_value} = Task.await(task_4)

    # So far the test would validate if we were calling the generator each time,
    # but the generation function should have been called only once.

    assert_receive :generator_called
    refute_receive :generator_called
  end

  test "returns failures to all waiters" do
    name = :concurrent_check_error
    _pid = start_supervised!({Cache, name: name})

    parent = self()

    pkey = make_ref()

    # The generator will fail once and the return success. So it will be called
    # two times.

    generator = fn ->
      # generator sleeps a bit so we do not test that the two calls happen
      # serially
      send(parent, :generator_called)
      Process.sleep(100)

      result =
        if :persistent_term.get(pkey, false) do
          {:ok, :success}
        else
          # first call when the flag is not set
          {:error, :some_failure}
        end

      :persistent_term.put(pkey, true)
      Process.sleep(100)
      result
    end

    task_1 = Task.async(fn -> Cache.get_or_generate(name, :some_key, generator) end)
    task_2 = Task.async(fn -> Cache.get_or_generate(name, :some_key, generator) end)
    task_3 = Task.async(fn -> Cache.get_or_generate(name, :some_key, generator) end)
    task_4 = Task.async(fn -> Cache.get_or_generate(name, :some_key, generator) end)

    # One of the tasks will receive the error, but other tasks will benefit from
    # the second call.
    assert [{:error, :some_failure}, {:ok, :success}, {:ok, :success}, {:ok, :success}] =
             Enum.sort([
               Task.await(task_1),
               Task.await(task_2),
               Task.await(task_3),
               Task.await(task_4)
             ])

    # So far the test would validate if we were calling the generator each time,
    # but the generation function should have been called only once.

    assert_receive :generator_called
    assert_receive :generator_called
    refute_receive :generator_called
  end

  @tag :capture_log
  test "handles exit or raise in generator" do
    name = :concurrent_check_exit
    _pid = start_supervised!({Cache, name: name})

    parent = self()

    pkey = make_ref()

    # Same as in the error test, the generator will fail once and the return
    # success. So it will be called two times.

    generator = fn ->
      send(parent, :generator_called)
      Process.sleep(100)

      result =
        if :persistent_term.get(pkey, false) do
          {:ok, :success}
        else
          # first call when the flag is not set
          :persistent_term.put(pkey, true)
          exit(:some_exit_reason)
        end

      Process.sleep(100)
      result
    end

    task_1 = Task.async(fn -> Cache.get_or_generate(name, :some_key, generator) end)
    task_2 = Task.async(fn -> Cache.get_or_generate(name, :some_key, generator) end)
    task_3 = Task.async(fn -> Cache.get_or_generate(name, :some_key, generator) end)
    task_4 = Task.async(fn -> Cache.get_or_generate(name, :some_key, generator) end)

    assert [{:error, :some_exit_reason}, {:ok, :success}, {:ok, :success}, {:ok, :success}] =
             Enum.sort([
               Task.await(task_1),
               Task.await(task_2),
               Task.await(task_3),
               Task.await(task_4)
             ])

    assert_receive :generator_called
    assert_receive :generator_called
    refute_receive :generator_called
  end

  @tag :capture_log
  test "handles concurrent cache tasks" do
    name = :concurrent_check_exit
    _pid = start_supervised!({Cache, name: name})

    pkey_prefix = make_ref()

    # generator will fail 3 times and succeed on the 4th

    generator = fn key ->
      pkey = {pkey_prefix, key}

      Process.sleep(200)
      n_call = :persistent_term.get(pkey, 1)
      :persistent_term.put(pkey, n_call + 1)

      if n_call == 4 do
        {:ok, {:success, key, n_call}}
      else
        exit({:some_exit_reason, key, n_call})
      end
    end

    generator_for = fn key ->
      fn -> generator.(key) end
    end

    task_11 = Task.async(fn -> Cache.get_or_generate(name, :some_key_1, generator_for.(:some_key_1)) end)
    task_12 = Task.async(fn -> Cache.get_or_generate(name, :some_key_1, generator_for.(:some_key_1)) end)
    task_13 = Task.async(fn -> Cache.get_or_generate(name, :some_key_1, generator_for.(:some_key_1)) end)
    task_14 = Task.async(fn -> Cache.get_or_generate(name, :some_key_1, generator_for.(:some_key_1)) end)
    task_15 = Task.async(fn -> Cache.get_or_generate(name, :some_key_1, generator_for.(:some_key_1)) end)

    task_21 = Task.async(fn -> Cache.get_or_generate(name, :some_key_2, generator_for.(:some_key_2)) end)
    task_22 = Task.async(fn -> Cache.get_or_generate(name, :some_key_2, generator_for.(:some_key_2)) end)
    task_23 = Task.async(fn -> Cache.get_or_generate(name, :some_key_2, generator_for.(:some_key_2)) end)
    task_24 = Task.async(fn -> Cache.get_or_generate(name, :some_key_2, generator_for.(:some_key_2)) end)
    task_25 = Task.async(fn -> Cache.get_or_generate(name, :some_key_2, generator_for.(:some_key_2)) end)

    assert [
             {:error, {:some_exit_reason, :some_key_1, 1}},
             {:error, {:some_exit_reason, :some_key_1, 2}},
             {:error, {:some_exit_reason, :some_key_1, 3}},
             {:error, {:some_exit_reason, :some_key_2, 1}},
             {:error, {:some_exit_reason, :some_key_2, 2}},
             {:error, {:some_exit_reason, :some_key_2, 3}},
             {:ok, {:success, :some_key_1, 4}},
             {:ok, {:success, :some_key_1, 4}},
             {:ok, {:success, :some_key_2, 4}},
             {:ok, {:success, :some_key_2, 4}}
           ] =
             Enum.sort([
               Task.await(task_11),
               Task.await(task_12),
               Task.await(task_13),
               Task.await(task_14),
               Task.await(task_15),
               Task.await(task_21),
               Task.await(task_22),
               Task.await(task_23),
               Task.await(task_24),
               Task.await(task_25)
             ])
  end
end
