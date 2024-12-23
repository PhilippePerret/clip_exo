defmodule ClipExo.ExoSchema do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :name, :string
    field :path, :string
    field :reference, :string
    field :titre, :string
    field :auteur, :string
    field :created_at, :date
    field :revised_by, :string
    field :application, {:array, :string}
    field :body, :string
    field :rubriques, {:array, :string}
    field :rubrique_mission, :string
    field :rubrique_objectif, :string
    field :rubrique_scenario, :string
    field :rubrique_aide, :string
    field :rubrique_recommandations, :string
    field :competences, {:array, :string}
    field :niveau, :string
    field :duree_min, :integer # en minutes
    field :duree_max, :integer # en minutes
    field :duree, :string # p.e. "Entre une 1/2 heure et 1 heure"
  end

  def changeset(schema, attrs) do
    attrs
    |> IO.inspect(label: "\nATTRS in changeset")
    rubriques =
      ["mission","objectif","scenario","aide","recommandation"]
      |> Enum.map(fn x ->
          if attrs["rubrique_" <> x] do
            IO.puts "La rubrique #{x} est prise"
            x
          else
            IO.puts "La rubrique #{x} n'est pas prise"
            nil
          end
        end)
      |> Enum.reject(fn x -> x == nil end)
      |> IO.inspect(label: "\nRubriques à la fin")

    attrs = Map.merge(attrs, %{rubriques: rubriques})

    schema
    |> cast(attrs, [:name, :path, :reference, :titre, :auteur, :created_at, :body, :rubriques, :competences, :duree_min, :duree_max])
    |> validate_required([:name, :path, :titre, :auteur, :body])
    |> validate_format(:duree, ~r/\[ ?[0-9]+, ?[0-9]+ ?\]/, message: "La durée doit être formatée de cette manière : [<durée min en minutes>, <durée max en minutes>]. Par exemple «[15, 30]».")
  end

end
