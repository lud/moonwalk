defmodule Moonwalk.Schema.Vocabulary do
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
      Helpers.reduce_while_ok(unquote(validators), unquote(data), fn {k, v}, data ->
        unquote(f)(data, {k, v}, unquote(ctx))
      end)
    end
  end

  defmacro pass(ast) do
    {:when, _, [{_fun_name, _, [data_var, _tuple, _ctx]}, _]} = ast

    quote do
      defp unquote(ast) do
        {:ok, unquote(data_var)}
      end
    end
  end
end
