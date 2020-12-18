defmodule Shlinkedin.Profiles.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notifications" do
    field :read, :boolean, default: false
    belongs_to :profile, Shlinkedin.Profiles.Profile, foreign_key: :from_profile_id
    field :to_profile_id, :id
    field :post_id, :id
    field :type, :string
    field :body, :string
    field :action, :string

    timestamps()
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:from_profile_id, :to_profile_id, :post_id, :type, :body, :read])
  end
end
