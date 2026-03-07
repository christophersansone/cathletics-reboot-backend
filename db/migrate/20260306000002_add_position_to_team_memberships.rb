class AddPositionToTeamMemberships < ActiveRecord::Migration[8.1]
  def change
    add_column :team_memberships, :position, :string
  end
end
