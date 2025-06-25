defmodule Moonwalk.Internal.SpecObject do
  @moduledoc false

  # Setup for various protocols implemented by the Objects definition of the 3.1
  # specification.

  IO.warn("remove fallback impl of normalize in quoted")

  defmacro __using__(_) do
    quote do
      import Moonwalk.Internal.Normalizer
      @behaviour Moonwalk.Internal.Normalizer
      @behaviour Access
      snake_object_name =
        __MODULE__
        |> Module.split()
        |> List.last()
        |> Macro.underscore()

      object_name =
        snake_object_name
        |> String.replace(~r{(^|_).}, fn
          "_" <> char -> " " <> String.upcase(char)
          char -> " " <> String.upcase(char)
        end)

      object_fragment =
        snake_object_name
        |> String.replace("_", "-")
        |> Kernel.<>("-object")

      obect_link = "https://spec.openapis.org/oas/v3.1.1.html##{object_fragment}"

      @moduledoc "Representation of the [#{object_name} Object](#{obect_link}) in OpenAPI Specification."

      @impl Moonwalk.Internal.Normalizer
      @spec normalize!(term, term) :: no_return
      def normalize!(_, _) do
        raise """
        unimplemented callback in #{inspect(__MODULE__)}

            @impl true
            def normalize!(data, ctx) do
              data
              |> from(__MODULE__, ctx)
              |> collect()
            end
        """
      end

      @impl Access
      def fetch(t, key) do
        Map.fetch(t, key)
      end

      @impl Access
      @spec get_and_update(term, term, term) :: no_return()
      def get_and_update(_t, _key, _fun) do
        raise "should not be used"
      end

      @impl Access
      @spec pop(term, term) :: no_return()
      def pop(_t, _key) do
        raise "should not be used"
      end

      defoverridable normalize!: 2
    end
  end
end
