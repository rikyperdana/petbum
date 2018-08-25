if Meteor.isServer

	Meteor.publish \coll, (name, sel, mod) -> coll[name]find sel, mod

	Meteor.methods do
		consolelog: (doc) ->
			console.log doc
