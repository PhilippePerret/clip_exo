defmodule ClipExo.ExoSchema do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do  
    field :titre, :string
    field :auteur, :string
    field :created_at, :naive_datetime
    field :revised_by, :string
    field :body, :string
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:titre, :auteur, :created_at, :body])
    |> validate_required([:titre, :auteur, :body])
  end

end