defmodule Moonwalk.Helpers do
  @type result :: {:ok, term} | {:error, term}
  @type result(t) :: {:ok, t} | {:error, term}

  # @spec map_ok(Enumerable.t(), (term -> result(term))) :: result([term])
  # def map_ok(enum, f) when is_function(f, 1) do
  #   Enum.reduce_while(enum, [], fn item, acc ->
  #     case f.(item) do
  #       {:ok, result} -> {:cont, [result | acc]}
  #       {:error, _} = err -> {:halt, err}
  #       other -> raise ArgumentError, "bad return from map_ok callback: #{inspect(other)}"
  #     end
  #   end)
  #   |> case do
  #     {:error, _} = err -> err
  #     acc -> {:ok, :lists.reverse(acc)}
  #   end
  # end

  @spec reduce_ok(Enumerable.t(), term, (term, term -> result)) :: result
  def reduce_ok(enum, initial, f) when is_function(f, 2) do
    Enum.reduce_while(enum, initial, fn item, acc ->
      case f.(item, acc) do
        {:ok, new_acc} -> {:cont, new_acc}
        {:error, _} = err -> {:halt, err}
        other -> raise ArgumentError, "bad return from reduce_ok callback: #{inspect(other)}"
      end
    end)
    |> case do
      {:error, _} = err -> err
      acc -> {:ok, acc}
    end
  end
end
