puts "Seeding Cathletics..."

# ---------------------------------------------------------------------------
# OAuth Application (first-party Ember client)
# ---------------------------------------------------------------------------
app = Doorkeeper::Application.find_or_create_by!(name: "Cathletics Web") do |a|
  a.redirect_uri = "urn:ietf:wg:oauth:2.0:oob"
  a.confidential = false
end
puts "  OAuth app: #{app.name} (uid: #{app.uid})"

# ---------------------------------------------------------------------------
# Users
# ---------------------------------------------------------------------------
admin_tom = User.find_or_create_by!(email: "tom@example.com") do |u|
  u.first_name = "Tom"
  u.last_name = "Smith"
  u.password = "password"
  u.gender = :male
  u.date_of_birth = Date.new(1985, 3, 14)
end

admin_katie = User.find_or_create_by!(email: "katie@example.com") do |u|
  u.first_name = "Katie"
  u.last_name = "Smith"
  u.password = "password"
  u.gender = :female
  u.date_of_birth = Date.new(1987, 7, 22)
end

parent_mike = User.find_or_create_by!(email: "mike@example.com") do |u|
  u.first_name = "Mike"
  u.last_name = "Johnson"
  u.password = "password"
  u.gender = :male
  u.date_of_birth = Date.new(1982, 11, 5)
end

parent_sarah = User.find_or_create_by!(email: "sarah@example.com") do |u|
  u.first_name = "Sarah"
  u.last_name = "Johnson"
  u.password = "password"
  u.gender = :female
  u.date_of_birth = Date.new(1984, 9, 30)
end

coach_dave = User.find_or_create_by!(email: "dave@example.com") do |u|
  u.first_name = "Dave"
  u.last_name = "Martinez"
  u.password = "password"
  u.gender = :male
  u.date_of_birth = Date.new(1978, 1, 10)
end

# Children (no email/password)
child_jack = User.find_or_create_by!(first_name: "Jack", last_name: "Smith", date_of_birth: Date.new(2015, 5, 12)) do |u|
  u.gender = :male
  u.grade_level = 5
  u.nickname = "JJ"
end

child_emma = User.find_or_create_by!(first_name: "Emma", last_name: "Smith", date_of_birth: Date.new(2017, 8, 3)) do |u|
  u.gender = :female
  u.grade_level = 3
end

child_liam = User.find_or_create_by!(first_name: "Liam", last_name: "Johnson", date_of_birth: Date.new(2014, 2, 20)) do |u|
  u.gender = :male
  u.grade_level = 6
end

child_olivia = User.find_or_create_by!(first_name: "Olivia", last_name: "Johnson", date_of_birth: Date.new(2016, 12, 1)) do |u|
  u.gender = :female
  u.grade_level = 4
end

puts "  Created #{User.count} users"

# ---------------------------------------------------------------------------
# Families
# ---------------------------------------------------------------------------
smith_family = Family.find_or_create_by!(name: "The Smith Family (Tom+Katie)")
johnson_family = Family.find_or_create_by!(name: "The Johnson Family (Mike+Sarah)")
martinez_family = Family.find_or_create_by!(name: "The Martinez Family (Dave)")

[
  [smith_family, admin_tom, :parent],
  [smith_family, admin_katie, :parent],
  [smith_family, child_jack, :child],
  [smith_family, child_emma, :child],
  [johnson_family, parent_mike, :parent],
  [johnson_family, parent_sarah, :parent],
  [johnson_family, child_liam, :child],
  [johnson_family, child_olivia, :child],
  [martinez_family, coach_dave, :parent],
].each do |family, user, role|
  FamilyMembership.find_or_create_by!(family: family, user: user) do |fm|
    fm.role = role
  end
end

puts "  Created #{Family.count} families with #{FamilyMembership.count} memberships"

# ---------------------------------------------------------------------------
# Organizations
# ---------------------------------------------------------------------------
st_marys = Organization.find_or_create_by!(slug: "st-marys-academy") do |o|
  o.name = "St. Mary's Academy"
end

st_josephs = Organization.find_or_create_by!(slug: "st-josephs-school") do |o|
  o.name = "St. Joseph's School"
end

puts "  Created #{Organization.count} organizations"

# ---------------------------------------------------------------------------
# Organization Memberships
# ---------------------------------------------------------------------------
[
  [st_marys, admin_tom, :admin],
  [st_marys, admin_katie, :member],
  [st_marys, parent_mike, :member],
  [st_marys, parent_sarah, :member],
  [st_marys, coach_dave, :member],
  [st_josephs, admin_katie, :admin],
  [st_josephs, parent_sarah, :member],
].each do |org, user, role|
  OrganizationMembership.find_or_create_by!(organization: org, user: user) do |om|
    om.role = role
  end
end

puts "  Created #{OrganizationMembership.count} organization memberships"

# ---------------------------------------------------------------------------
# Activity Types
# ---------------------------------------------------------------------------
football = ActivityType.find_or_create_by!(organization: st_marys, name: "Football") do |at|
  at.description = "Fall tackle football program"
end

basketball = ActivityType.find_or_create_by!(organization: st_marys, name: "Basketball") do |at|
  at.description = "Winter basketball program"
end

choir = ActivityType.find_or_create_by!(organization: st_marys, name: "Choir") do |at|
  at.description = "Year-round parish choir"
end

band = ActivityType.find_or_create_by!(organization: st_marys, name: "Band") do |at|
  at.description = "Concert and marching band"
end

volleyball = ActivityType.find_or_create_by!(organization: st_josephs, name: "Volleyball") do |at|
  at.description = "Fall volleyball program"
end

puts "  Created #{ActivityType.count} activity types"

# ---------------------------------------------------------------------------
# Seasons
# ---------------------------------------------------------------------------
football_fall_2026 = Season.find_or_create_by!(activity_type: football, name: "Fall 2026") do |s|
  s.start_date = Date.new(2026, 8, 1)
  s.end_date = Date.new(2026, 11, 15)
  s.registration_start_at = Time.zone.parse("2026-05-01 08:00:00")
  s.registration_end_at = Time.zone.parse("2026-07-15 23:59:59")
end

basketball_winter_2027 = Season.find_or_create_by!(activity_type: basketball, name: "Winter 2026-2027") do |s|
  s.start_date = Date.new(2026, 11, 1)
  s.end_date = Date.new(2027, 2, 28)
  s.registration_start_at = Time.zone.parse("2026-08-15 08:00:00")
  s.registration_end_at = Time.zone.parse("2026-10-15 23:59:59")
end

choir_2026 = Season.find_or_create_by!(activity_type: choir, name: "2026-2027") do |s|
  s.start_date = Date.new(2026, 9, 1)
  s.end_date = Date.new(2027, 5, 31)
  s.registration_start_at = Time.zone.parse("2026-07-01 08:00:00")
  s.registration_end_at = Time.zone.parse("2026-08-31 23:59:59")
end

volleyball_fall_2026 = Season.find_or_create_by!(activity_type: volleyball, name: "Fall 2026") do |s|
  s.start_date = Date.new(2026, 8, 15)
  s.end_date = Date.new(2026, 10, 31)
  s.registration_start_at = Time.zone.parse("2026-06-01 08:00:00")
  s.registration_end_at = Time.zone.parse("2026-08-01 23:59:59")
end

puts "  Created #{Season.count} seasons"

# ---------------------------------------------------------------------------
# Leagues
# ---------------------------------------------------------------------------
football_5_6_boys = League.find_or_create_by!(season: football_fall_2026, gender: :male, min_grade: 5, max_grade: 6) do |l|
  l.name = "5th-6th Grade Boys Football"
  l.capacity = 40
end

football_3_4_boys = League.find_or_create_by!(season: football_fall_2026, gender: :male, min_grade: 3, max_grade: 4) do |l|
  l.name = "3rd-4th Grade Boys Football"
  l.capacity = 30
end

basketball_5_6_girls = League.find_or_create_by!(season: basketball_winter_2027, gender: :female, min_grade: 5, max_grade: 6) do |l|
  l.name = "5th-6th Grade Girls Basketball"
end

basketball_5_6_boys = League.find_or_create_by!(season: basketball_winter_2027, gender: :male, min_grade: 5, max_grade: 6) do |l|
  l.name = "5th-6th Grade Boys Basketball"
end

choir_all = League.find_or_create_by!(season: choir_2026, min_grade: 3, max_grade: 8) do |l|
  l.name = "3rd-8th Grade Choir"
end

volleyball_5_6_girls = League.find_or_create_by!(season: volleyball_fall_2026, gender: :female, min_grade: 5, max_grade: 6) do |l|
  l.name = "5th-6th Grade Girls Volleyball"
end

puts "  Created #{League.count} leagues"

# ---------------------------------------------------------------------------
# Teams
# ---------------------------------------------------------------------------
football_5_6_a = Team.find_or_create_by!(league: football_5_6_boys, name: "A Team")
football_5_6_b = Team.find_or_create_by!(league: football_5_6_boys, name: "B Team")
football_3_4   = Team.find_or_create_by!(league: football_3_4_boys, name: "3rd-4th Grade Boys")
bball_girls    = Team.find_or_create_by!(league: basketball_5_6_girls, name: "5th-6th Girls")
bball_boys     = Team.find_or_create_by!(league: basketball_5_6_boys, name: "5th-6th Boys")
choir_team     = Team.find_or_create_by!(league: choir_all, name: "Parish Choir")
vball_girls    = Team.find_or_create_by!(league: volleyball_5_6_girls, name: "5th-6th Girls Volleyball")

puts "  Created #{Team.count} teams"

# ---------------------------------------------------------------------------
# Team Memberships (coaches)
# ---------------------------------------------------------------------------
TeamMembership.find_or_create_by!(team: football_5_6_a, user: coach_dave) do |tm|
  tm.role = :coach
end

TeamMembership.find_or_create_by!(team: football_5_6_b, user: admin_tom) do |tm|
  tm.role = :coach
end

puts "  Created #{TeamMembership.count} team memberships"

# ---------------------------------------------------------------------------
# Registrations
# ---------------------------------------------------------------------------
[
  [football_5_6_boys, child_jack, admin_tom, :confirmed],
  [football_5_6_boys, child_liam, parent_mike, :confirmed],
  [basketball_5_6_boys, child_jack, admin_katie, :pending],
  [basketball_5_6_girls, child_olivia, parent_sarah, :pending],
  [choir_all, child_emma, admin_katie, :confirmed],
  [choir_all, child_olivia, parent_sarah, :confirmed],
  [football_3_4_boys, child_emma, admin_katie, :not_selected],
].each do |league, child, parent, status|
  Registration.find_or_create_by!(league: league, user: child) do |r|
    r.registered_by = parent
    r.status = status
  end
end

puts "  Created #{Registration.count} registrations"

# ---------------------------------------------------------------------------
# Team Memberships (players from confirmed registrations)
# ---------------------------------------------------------------------------
TeamMembership.find_or_create_by!(team: football_5_6_a, user: child_jack) do |tm|
  tm.role = :player
end

TeamMembership.find_or_create_by!(team: football_5_6_a, user: child_liam) do |tm|
  tm.role = :player
end

TeamMembership.find_or_create_by!(team: choir_team, user: child_emma) do |tm|
  tm.role = :player
end

TeamMembership.find_or_create_by!(team: choir_team, user: child_olivia) do |tm|
  tm.role = :player
end

puts "  Created #{TeamMembership.count} team memberships (including players)"

puts "\nSeeding complete!"
puts "  Login as admin:  tom@example.com / password"
puts "  Login as parent: mike@example.com / password"
puts "  Login as coach:  dave@example.com / password"
puts "  OAuth app UID:   #{app.uid}"
puts "  OAuth app secret: #{app.secret}"
