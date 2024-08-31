defmodule Moonwalk.Schema.Vocabulary.V202012.Format do
  alias Moonwalk.Schema.Validator
  use Moonwalk.Schema.Vocabulary, priority: 300

  # TODO
  # * provide an option :formats that accepts
  #   - true: always validate formats
  #   - false: do not validate formats
  #   - :default : validate format if a dummy vocabulary for
  #     https://json-schema.org/draft/2020-12/vocab/format-assertion is selected
  #   - {true | false | :default, (format, data -> boolean)}
  # * Define a vocabulary that does nothing, as we will implement everything in
  #   this module, but we can check if the vocabulary is loaded

  @impl true
  def init_validators(opts) do
    # The assert option is defined at the vocabulary level, as vocabularies are
    # defined like so:
    # "https://json-schema.org/draft/2020-12/vocab/format-annotation" =>
    #     Vocabulary.V202012.Format,
    # "https://json-schema.org/draft/2020-12/vocab/format-assertion" =>
    #     {Vocabulary.V202012.Format, assert: true},
    default_assert =
      case Keyword.fetch(opts, :assert) do
        {:ok, true} -> true
        _ -> false
      end

    %{default_assert: default_assert}
  end

  @impl true
  def take_keyword({"format", format}, acc, ctx, _) do
    validate_formats? =
      case {acc.default_assert, ctx.opts[:formats]} do
        {_, true} -> true
        {_, false} -> false
        {do?, nil} -> do?
        {do?, :default} -> do?
      end

    if validate_formats? do
      {:ok, Map.put(acc, :format, format), ctx}
    else
      {:ok, acc, ctx}
    end
  end

  ignore_any_keyword()

  @impl true
  def finalize_validators(acc) do
    acc
    |> Map.take([:format])
    |> Map.to_list()
    |> case do
      [] -> :ignore
      [{:format, _}] = list -> list
    end
  end

  @impl true
  def validate(data, [format: format], vdr) do
    if validate_format(format, data) do
      {:ok, data, vdr}
    else
      {:error, Validator.with_error(vdr, :format, data, format: format)}
    end
  end

  defp validate_format(_, data) when not is_binary(data) do
    true
  end

  defp validate_format("date-time", data) do
    case DateTime.from_iso8601(data) do
      {:ok, _, _} -> true
      _ -> false
    end
  end

  defp validate_format("date", data) do
    case Date.from_iso8601(data) do
      {:ok, _} -> true
      _ -> false
    end
  end

  defp validate_format("time", data) do
    case Time.from_iso8601(data) do
      {:ok, _} -> true
      _ -> false
    end
  end

  defp validate_format("ipv4", data) do
    case :inet.parse_strict_address(String.to_charlist(data)) do
      {:ok, {_, _, _, _}} -> true
      _ -> false
    end
  end

  defp validate_format("ipv6", data) do
    case :inet.parse_strict_address(String.to_charlist(data)) do
      {:ok, {_, _, _, _, _, _, _, _}} -> not String.contains?(data, "%")
      _ -> false
    end
  end

  defp validate_format("regex", data) do
    case Regex.compile(data) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  defp validate_format("unknown", _data) do
    true
  end

  # ---------------------------------------------------------------------------

  @impl true
  def format_error(:format, %{format: format}, _data) do
    "value does not respect the '#{format}' format"
  end
end
