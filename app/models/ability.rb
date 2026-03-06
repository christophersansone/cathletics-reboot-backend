class Ability
  include CanCan::Ability

  attr_reader :user, :organization

  def initialize(user, organization = nil)
    @user = user
    @organization = organization

    return unless user

    define_user_abilities
    define_family_abilities
    define_organization_abilities if organization
  end

  private

  def define_user_abilities
    can :read, User, id: user.id
    can :update, User, id: user.id

    can :read, Family, id: user.family_ids
    can :read, FamilyMembership, family_id: user.family_ids
  end

  def define_family_abilities
    family_ids = user.family_memberships.where(role: [:parent, :guardian]).pluck(:family_id)

    can :manage, FamilyMembership, family_id: family_ids
    can :manage, FamilyInvitation, family_id: family_ids
    can :update, Family, id: family_ids

    child_ids = FamilyMembership.where(family_id: family_ids, role: :child).pluck(:user_id)
    can :read, User, id: child_ids
    can :update, User, id: child_ids
    can :create, Registration, user_id: child_ids
    can :read, Registration, user_id: [user.id] + child_ids
    can [:cancel], Registration, registered_by_id: user.id
  end

  def define_organization_abilities
    membership = organization.organization_memberships.find_by(user: user)
    return unless membership

    if membership.admin?
      define_admin_abilities
    else
      define_member_abilities
    end

    define_team_role_abilities
  end

  def define_admin_abilities
    can :manage, Organization, id: organization.id
    can :read_members, Organization, id: organization.id
    can :manage, OrganizationMembership, organization_id: organization.id
    can :manage, ActivityType, organization_id: organization.id
    can :manage, Season, activity_type: { organization_id: organization.id }
    can :manage, League, season: { activity_type: { organization_id: organization.id } }
    can :manage, Team, league: { season: { activity_type: { organization_id: organization.id } } }
    can :manage, TeamMembership, team: { league: { season: { activity_type: { organization_id: organization.id } } } }
    can :manage, Registration, league: { season: { activity_type: { organization_id: organization.id } } }
  end

  def define_member_abilities
    can :read, Organization, id: organization.id
    can :read, ActivityType, organization_id: organization.id
    can :read, Season, activity_type: { organization_id: organization.id }
    can :read, League, season: { activity_type: { organization_id: organization.id } }
    can :read, Team, league: { season: { activity_type: { organization_id: organization.id } } }
    can :read, TeamMembership, team: { league: { season: { activity_type: { organization_id: organization.id } } } }

    can :create, Registration
  end

  def define_team_role_abilities
    coached_team_ids = user.team_memberships.where(role: [:coach, :assistant_coach]).pluck(:team_id)
    return if coached_team_ids.empty?

    can :read, Team, id: coached_team_ids
    can :manage, TeamMembership, team_id: coached_team_ids
    can :read, Registration, league_id: Team.where(id: coached_team_ids).pluck(:league_id)
  end
end
