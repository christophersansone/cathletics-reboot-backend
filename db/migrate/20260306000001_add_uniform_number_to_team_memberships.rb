class AddUniformNumberToTeamMemberships < ActiveRecord::Migration[8.1]
  def change
    add_column :team_memberships, :uniform_number, :string
  end
end
