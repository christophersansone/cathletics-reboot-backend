class AddTimeZoneToOrganizationsAndSeasons < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :time_zone, :string, null: false, default: "America/New_York"
    add_column :seasons, :time_zone, :string
  end
end
