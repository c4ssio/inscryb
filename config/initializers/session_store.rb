# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_inscryb_repair_session',
  :secret      => 'f6522b3aa7b0d3194e5b1747805ed07937ecd9ba8394fe73a179903a64d0eef629ab29b1cc61bee2dc2d7c1a613c0490a7f2997c6940606114cbd660958001c7'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
