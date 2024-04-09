defmodule Moonwalk.Schema.Vocabulary do
  alias Moonwalk.Schema.Validator
  alias Moonwalk.Helpers
  alias Moonwalk.Schema.Builder

  @type validators :: term
  @type pair :: {binary, term}
  @type data :: %{optional(binary) => data} | [data] | binary | boolean | number | nil
  @callback init_validators :: validators
  @callback take_keyword(pair, validators, bld :: Builder.t()) ::
              {:ok, validators(), Builder.t()} | :ignore | {:error, term}
  @callback finalize_validators(validators) :: :ignore | validators
  @callback validate(data, validators, vdr :: Validator.t()) :: {:ok, data} | {:error, Validator.t()}

  @doc """
  Returns the priority for applyting this module to the data.

  Lower values (close to zero) will be applied first. You can think "order"
  instead of "priority" but several modules can share the same priority value.

  This can be useful to define vocabularies that depend on other vocabularies.
  For instance, the `max_contains` keyword in the validation vocabulary has
  lower priority (higher number) as the applicator vocabulary that defines
  `contains`. So when validating `max_contains`, the validator for `contains`
  will have registered the matched number of items in the validator `public`
  state.

  Modules shipped in this library have priority of 100, 200, etc. up to 900 so
  you can interleave your own vocabularies. Casting values to non-validable
  terms (such as structs or dates) should be done by vocabularies with a
  priority of 1000 and above.
  """
  @callback priority() :: pos_integer()

  defmacro __using__(opts) do
    priority_callback =
      case Keyword.fetch(opts, :priority) do
        {:ok, n} when is_integer(n) and n > 0 ->
          quote bind_quoted: [n: n] do
            @impl true
            def priority do
              unquote(n)
            end
          end

        :error ->
          []

        {:ok, other} ->
          raise ArgumentError,
                "expected :priority option to be given as a positive integer literal, got: #{inspect(other)}"
      end

    quote do
      import unquote(__MODULE__)
      @behaviour unquote(__MODULE__)
      require Moonwalk.Schema.Validator
      unquote(priority_callback)
    end
  end

  @doc false
  defmacro todo_take_keywords(bin_keys) do
    IO.warn("called todo_take_keywords from #{inspect(__CALLER__.module)}")

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

  defmacro consume_keyword(kw) do
    quote do
      def take_keyword({unquote(kw), _}, acc, ctx) do
        {:ok, acc, ctx}
      end
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
