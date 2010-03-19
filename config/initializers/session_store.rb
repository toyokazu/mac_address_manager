# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_mac-address-filter-manager_session',
  :secret      => 'ba70b879780f3160d15069f2014c5bbcc19ccc34bef9391fd495968eb2099bbd9469620190984ea84afc154664177a34068fd6d4f1856f1d2d1cf58d225858bf'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
