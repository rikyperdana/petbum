if Meteor.isServer

	Meteor.publish \coll, (name, sel = {}, mod = {}) ->
		coll[name]find sel, mod

	Meteor.publish \users, (sel = {}, opts = {}) ->
		Meteor.users.find sel, opts

	Meteor.methods do

		newUser: (doc) ->
			if Accounts.findUserByUsername doc.username
				for i in <[ username password ]>
					Accounts["set#{_.startCase i}"] that._id, doc[i]
			else Accounts.createUser doc
