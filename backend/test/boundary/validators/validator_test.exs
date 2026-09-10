defmodule Boundary.Validators.ValidatorTest do
  alias NewspaperScraper.Boundary.Validator
  use ExUnit.Case, async: true

  describe "optional/4" do
    test "works as expected when optional fields are not present" do
      fields = %{}
      validator = fn _ -> Validator.check(false, "test_msg") end
      validation = Validator.optional([], fields, :test_field, validator)

      assert [] === validation
    end

    test "works as expected when optional fields are present" do
      fields = %{test_field: "hola"}
      validator = fn _ -> Validator.check(is_binary(fields.test_field), "test_msg") end
      validation = Validator.optional([], fields, :test_field, validator)

      assert [] === validation
    end


    test "works as expected when optional fields are present but fail validation" do
      fields = %{test_field: "hola"}
      validator = fn _ -> Validator.check(fields.test_field + 1, "test_msg") end
      validation = Validator.optional([], fields, :test_field, validator)

      assert {:error, _} = validation
    end
  end
end
