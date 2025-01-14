defmodule Shlinkedin.Ads.Ad do
  use Ecto.Schema
  import Ecto.Changeset
  alias Shlinkedin.Ads.Ad
  alias Shlinkedin.Ads
  alias Shlinkedin.Profiles.Profile
  alias Shlinkedin.Points

  schema "ads" do
    field(:body, :string)
    field(:media_url, :string)
    field(:slug, :string)
    belongs_to(:profile, Shlinkedin.Profiles.Profile)
    belongs_to(:owner, Shlinkedin.Profiles.Profile, foreign_key: :owner_id)
    has_many(:clicks, Shlinkedin.Ads.Click, on_delete: :delete_all)
    has_many(:adlikes, Shlinkedin.Ads.AdLike, on_delete: :delete_all)
    field(:company, :string)
    field(:product, :string)
    field(:overlay, :string)
    field(:gif_url, :string)
    field(:overlay_color, :string)
    field(:removed, :boolean, default: false)
    field(:quantity, :integer, default: 1)
    field(:price, Money.Ecto.Amount.Type, default: "100")

    timestamps()
  end

  @doc false
  def changeset(ad, attrs) do
    ad
    |> cast(attrs, [
      :body,
      :media_url,
      :slug,
      :company,
      :product,
      :overlay,
      :overlay_color,
      :gif_url,
      :removed,
      :price,
      :owner_id
    ])
    |> validate_required([:body, :product])
    |> validate_required_inclusion([:gif_url, :media_url])
    |> validate_length(:body, min: 0, max: 250)
    |> validate_length(:company, max: 50)
    |> validate_length(:product, max: 50)
    |> validate_length(:overlay, max: 50)
    |> validate_number(:price, greater_than: 0)
  end

  def validate_required_inclusion(changeset, fields) do
    if Enum.any?(fields, fn field -> get_field(changeset, field) end),
      do: changeset,
      else:
        add_error(
          changeset,
          hd(fields),
          "Make sure you add either a photo or a gif"
        )
  end

  @doc """
  Validates that you have enough balance to create the ad.
  """
  def validate_affordable(
        %Ecto.Changeset{
          data: %Ad{profile_id: profile_id, product: product}
        } = changeset
      ) do
    validate_change(changeset, :price, fn
      :price, price ->
        profile = Shlinkedin.Profiles.get_profile_by_profile_id(profile_id)
        {:ok, cost} = Ads.calc_ad_cost(price)

        cond do
          Money.compare(profile.points, cost) < 0 ->
            [price: "You cannot afford to make this for #{cost}. You have #{profile.points}."]

          cost.amount < 0 ->
            net_worth = profile.points.amount
            tax = (net_worth * -0.1) |> trunc() |> Money.new(:SHLINK)

            Points.generate_wealth_given_amount(profile, tax, "Cheater tax")

            [
              price:
                "\n Ah, we have a cheater in our midst! Subtracting -10% of your net worth (#{tax})"
            ]

          cost.amount > 0 ->
            negative_cost = negative_money(cost)
            Points.generate_wealth_given_amount(profile, negative_cost, "Creating #{product}")
            []
        end
    end)
  end

  @doc """
  Validates that ad price is greater than zero
  """
  def validate_price_not_negative(%Ecto.Changeset{} = changeset) do
    validate_change(changeset, :price, fn
      :price, price ->
        {:ok, cost} = Ads.calc_ad_cost(price)

        if cost.amount <= 0 do
          [price: "Price cannot be negative"]
        else
          []
        end
    end)
  end

  defp negative_money(%Money{amount: amount} = money) do
    %{money | amount: -amount}
  end
end
