defmodule BrothTest.Message.User.UpdateTest do
  use ExUnit.Case, async: true
  use KousaTest.Support.EctoSandbox

  @moduletag :message

  alias Beef.Schemas.User
  alias Broth.Message.User.Update
  alias KousaTest.Support.Factory

  setup do
    # this "UNIT" test requires the db because the message gets
    # initialized off of information in the database.
    user = Factory.create(User)
    state = %Broth.SocketHandler{user_id: user.id}
    {:ok, uuid: UUID.uuid4(), state: state}
  end

  describe "when you send an update message to change muted state" do
    test "it populates update fields", %{uuid: uuid, state: state} do
      assert {:ok, %{payload: %Update{muted: true}}} =
               BrothTest.Support.Message.validate(
                 %{
                   "operator" => "user:update",
                   "payload" => %{"muted" => true},
                   "reference" => uuid
                 },
                 state
               )

      # short form also allowed
      assert {:ok, %{payload: %Update{muted: false}}} =
               BrothTest.Support.Message.validate(
                 %{
                   "op" => "user:update",
                   "p" => %{"muted" => false},
                   "ref" => uuid
                 },
                 state
               )
    end

    test "omitting the reference is not allowed", %{state: state} do
      assert {:error, %{errors: [reference: {"is required for Broth.Message.User.Update", _}]}} =
               BrothTest.Support.Message.validate(
                 %{
                   "operator" => "user:update",
                   "payload" => %{"muted" => true}
                 },
                 state
               )
    end

    test "providing the wrong datatype for muted state is disallowed",
         %{uuid: uuid, state: state} do
      assert {:error, %{errors: %{muted: "is invalid"}}} =
               BrothTest.Support.Message.validate(
                 %{
                   "operator" => "user:update",
                   "payload" => %{"muted" => "foobar"},
                   "reference" => uuid
                 },
                 state
               )

      assert {:error, %{errors: %{muted: "is invalid"}}} =
               BrothTest.Support.Message.validate(
                 %{
                   "operator" => "user:update",
                   "payload" => %{"muted" => ["foobar", "barbaz"]},
                   "reference" => uuid
                 },
                 state
               )
    end
  end

  describe "when you send an update message to change the username" do
    test "it populates update fields", %{uuid: uuid, state: state} do
      assert {:ok, %{payload: %Update{username: "foobar"}}} =
               BrothTest.Support.Message.validate(
                 %{
                   "operator" => "user:update",
                   "payload" => %{"username" => "foobar"},
                   "reference" => uuid
                 },
                 state
               )
    end

    test "it rejects attempting to delete the username", %{uuid: uuid, state: state} do
      assert {:error, %{errors: %{username: "can't be blank"}}} =
               BrothTest.Support.Message.validate(
                 %{
                   "operator" => "user:update",
                   "payload" => %{"username" => ""},
                   "reference" => uuid
                 },
                 state
               )

      assert {:error, %{errors: %{username: "can't be blank"}}} =
               BrothTest.Support.Message.validate(
                 %{
                   "operator" => "user:update",
                   "payload" => %{"username" => nil},
                   "reference" => uuid
                 },
                 state
               )
    end
  end
end
