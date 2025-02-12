defmodule BrothTest.Chat.DeleteMsgTest do
  use ExUnit.Case, async: true
  use KousaTest.Support.EctoSandbox

  alias Beef.Schemas.User
  alias Beef.Users
  alias BrothTest.WsClient
  alias BrothTest.WsClientFactory
  alias KousaTest.Support.Factory

  require WsClient

  setup do
    user = Factory.create(User)
    client_ws = WsClientFactory.create_client_for(user)

    {:ok, user: user, client_ws: client_ws}
  end

  describe "the websocket chat:delete_msg operation" do
    test "sends a message to the room", t do
      user_id = t.user.id
      # first, create a room owned by the primary user.
      {:ok, %{room: %{id: room_id}}} = Kousa.Room.create_room(t.user.id, "foo room", "foo", false)
      # make sure the user is in there.
      assert %{currentRoomId: ^room_id} = Users.get_by_id(t.user.id)

      # create a user that is logged in.
      listener = %{id: listener_id} = Factory.create(User)
      listener_ws = WsClientFactory.create_client_for(listener)

      # join the speaker user into the room
      Kousa.Room.join_room(listener_id, room_id)
      WsClient.assert_frame("new_user_join_room", _)

      # note that an asynchronous delete request doesn't really have
      # to make sense to anyone.

      # TODO: double check that the listener-id can't be hijacked
      # (is it only sent to early-block poor attempts to delete messages?)
      # maybe we should handle this at the frontend level?
      msg_id = UUID.uuid4()

      WsClient.send_msg(t.client_ws, "chat:delete_msg", %{
        "messageId" => msg_id,
        "userId" => listener_id
      })

      WsClient.assert_frame(
        "message_deleted",
        %{
          "deleterId" => ^user_id,
          "messageId" => ^msg_id
        },
        t.client_ws
      )

      WsClient.assert_frame(
        "message_deleted",
        %{
          "deleterId" => ^user_id,
          "messageId" => ^msg_id
        },
        listener_ws
      )
    end
  end
end
