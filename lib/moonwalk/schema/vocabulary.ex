defmodule Moonwalk.Schema.Vocabulary do
  alias Moonwalk.Helpers
  alias Moonwalk.Schema.Validator.Context
  alias Moonwalk.Schema.Builder
  alias Moonwalk.Schema.Validator.Error

  @type validators :: term
  @type pair :: {binary, term}
  @type data :: %{optional(binary) => data} | [data] | binary | boolean | number | nil
  @callback init_validators :: validators
  @callback take_keyword(pair, validators, bld :: Builder.t()) ::
              {:ok, validators(), Builder.t()} | :ignore | {:error, term}
  @callback finalize_validators(validators) :: :ignore | validators
  @callback validate(data, validators, ctx :: Context.t()) :: {:ok, data} | {:error, Error.t()}

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
      @behaviour unquote(__MODULE__)
      require Moonwalk.Schema.Validator
    end
  end

  @doc false
  defmacro todo_take_keywords(bin_keys) do
    quote bind_quoted: binding() do
      Enum.each(bin_keys, fn k ->
        def take_keyword({unquote(k) = k, _}, _, _) do
          u = Macro.underscore(k)
          ut = u |> String.trim("$")

          raise """
          TODO! in #{inspect(__MODULE__)}:
          #{__ENV__.file}

          def take_keyword({#{inspect(k)}, #{ut}}, acc, ctx) do
            {:ok, [{:"#{u}", #{ut}}|acc], ctx}
          end
          """
        end
      end)
    end
  end

  defmacro ignore_any_keyword do
    quote do
      def take_keyword(_, _, _) do
        :ignore
      end
    end
  end

  defmacro skip_keyword(kw) do
    quote do
      def take_keyword({unquote(kw), _}, acc, ctx) do
        {:ok, acc, ctx}
      end
    end
  end

  defmacro run_validators(data, validators, vdr, {:&, _, _} = f) do
    quote bind_quoted: binding() do
      Moonwalk.Schema.Validator.apply_all_fun(data, validators, vdr, f)
    end
  end

  IO.warn("TODO remove this clause")

  defmacro run_validators(data, validators, vdr, f) when is_atom(f) do
    IO.warn("TODO pass fun directly")

    quote do
      Moonwalk.Schema.Validator.apply_all_fun(unquote(data), unquote(validators), unquote(vdr), fn data, item, vdr ->
        unquote(f)(data, item, vdr)
      end)
    end
  end

  defmacro pass(ast) do
    case ast do
      {:when, _, _} ->
        raise "unsupported guard"

      {fun_name, _, [match_tuple]} ->
        quote do
          defp unquote(fun_name)(data, unquote(match_tuple), vdr) do
            {:ok, data, vdr}
          end
        end
    end
  end

  def take_sub(key, subraw, acc, ctx) when is_list(acc) do
    case Builder.build_sub(subraw, ctx) do
      {:ok, subvalidators, ctx} -> {:ok, [{key, subvalidators} | acc], ctx}
      {:error, _} = err -> err
    end
  end

  def take_integer(key, n, acc, ctx) when is_list(acc) do
    with {:ok, n} <- force_integer(n) do
      {:ok, [{key, n} | acc], ctx}
    end
  end

  defp force_integer(n) when is_integer(n) do
    {:ok, n}
  end

  defp force_integer(n) when is_float(n) do
    if Helpers.fractional_is_zero?(n) do
      {:ok, Helpers.trunc(n)}
    else
      {:error, "not an integer: #{inspect(n)}"}
    end
  end

  defp force_integer(other) do
    {:error, "not an integer: #{inspect(other)}"}
  end

  def take_number(key, n, acc, ctx) when is_list(acc) do
    with :ok <- check_number(n) do
      {:ok, [{key, n} | acc], ctx}
    end
  end

  defp check_number(n) when is_number(n) do
    :ok
  end

  defp check_number(other) do
    {:error, "not a number: #{inspect(other)}"}
  end

  def take_boolean(key, bool, acc, ctx) do
    with :ok <- check_boolean(bool) do
      {:ok, [{key, bool} | acc], ctx}
    end
  end

  defp check_boolean(b) when is_boolean(b) do
    :ok
  end

  defp check_boolean(other) do
    {:error, "not a boolean: #{inspect(other)}"}
  end
end
