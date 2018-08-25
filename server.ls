if Meteor.isServer

	Meteor.publish \coll, (name, sel = {}, mod = {}) ->
		coll[name]find sel, mod
