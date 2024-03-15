defmodule Moonwalk.Schema.Vocabulary do
  alias Moonwalk.Schema
  alias Moonwalk.Helpers
  alias Moonwalk.Schema.Validator.Context
  alias Moonwalk.Schema.BuildContext
  alias Moonwalk.Schema.Validator.Error

  @type validators :: term
  @type pair :: {binary, term}
  @type data :: %{optional(binary) => data} | [data] | binary | boolean | number | nil
  @callback init_validators :: validators
  @callback take_keyword(pair, validators, build_context :: BuildContext.t()) ::
              {:ok, validators(), BuildContext.t()} | :ignore | {:error, term}
  @callback finalize_validators(validators) :: :ignore | validators
  @callback validate(data, validators, context :: Context.t()) :: {:ok, data} | {:error, Error.t()}

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
      @behaviour unquote(__MODULE__)
      require Moonwalk.Schema.Validator.Context
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

  defmacro run_validators(data, validators, ctx, f) when is_atom(f) do
    quote do
      Helpers.reduce_ok(unquote(validators), unquote(data), fn {k, v}, data ->
        unquote(f)(data, {k, v}, unquote(ctx))
      end)
    end
  end

  defmacro pass(ast) do
    case ast do
      {:when, _, [{_fun_name, _, [data_var, _tuple, _ctx]}, _]} ->
        quote do
          defp unquote(ast) do
            {:ok, unquote(data_var)}
          end
        end

      {_fun_name, _, [data_var, _tuple, _ctx]} ->
        quote do
          defp unquote(ast) do
            {:ok, unquote(data_var)}
          end
        end
    end
  end

  def take_sub(key, subraw, acc, ctx) when is_list(acc) do
    case Schema.denormalize_sub(subraw, ctx) do
      {:ok, subvalidators, ctx} -> {:ok, [{key, subvalidators} | acc], ctx}
      {:error, _} = err -> err
    end
  end

  def take_integer(key, n, acc, ctx) when is_list(acc) do
    with :ok <- check_integer(n) do
      {:ok, [{key, n} | acc], ctx}
    end
  end

  defp check_integer(n) when is_integer(n) do
    :ok
  end

  defp check_integer(other) do
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
