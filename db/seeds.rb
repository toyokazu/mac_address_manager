# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#   
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)

# create admin user
# You should not edit admin user profiles. admin user and group is used as
# a default owner of MacAddress.
admin_user = User.create(:name => 'admin', :display_name => '管理者', :contact => 'root@example.com')
# create admin role
admin_role = Role.create(:name => 'admin', :display_name => '管理者')
admin_user.roles << admin_role
# admin_user = User.create(:name => 'akiyama', :display_name => 'Toyokazu Akiyama (admin)')
