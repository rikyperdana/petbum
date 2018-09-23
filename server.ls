if Meteor.isServer

	Meteor.publish \coll, (name, sel = {}, opt = {}) ->
		coll[name]find sel, opt

	Meteor.publish \users, (sel = {}, opt = {}) ->
		Meteor.users.find sel, opt

	Meteor.methods do

		newUser: (doc) ->
			if Accounts.findUserByUsername doc.username
				for i in <[ username password ]>
					Accounts["set#{_.startCase i}"] that._id, doc[i]
			else Accounts.createUser doc

		addRole: ({id, roles, group, poli}) ->
			Roles.addUsersToRoles id, (poli or roles), group

		rmRole: (id) -> Meteor.users.update {_id: id}, $set: roles: {}

		importRoles: (doc) ->
			if Accounts.findUserByUsername doc.username
				Roles.addUsersToRoles do
					that._id, (doc.poli or doc.role), doc.group

		import: (name, selector, modifier, arrName) ->
			find = coll[name]find selector
			if arrName
				if find then coll[name]update do
					{_id: find._id}, $push: "#that": modifier[that]0
				else coll[name]insert _.merge selector, modifier
			else coll[name]insert _.merge selector, modifier

		rmRawat: (idpasien, idrawat) -> coll.pasien.update idpasien,
			$set: rawat: coll.pasien.findOne(idpasien)rawat.filter ->
				it.idrawat isnt idrawat

		updateArrayElm: ({name, recId, scope, elmId, doc}) ->
			coll[name]update recId, $set: "#scope":
				coll[name]findOne(recId)[scope]map (i) ->
					if i["id#scope"] is elmId then doc else i

		serahObat: ({_id, obat}) ->
			batches = []
			for i in obat
				find = coll.gudang.findOne i.nama
				for j in [til i.jumlah]
					coll.gudang.update find._id, $set: batch:
						find.batch.map (k) ->
							unless k.diapotik > 0 then k
							else
								batches.push _.merge k, jumlah: 1
								_.assign k, diapotik: k.diapotik-1
			reducer = (res, inc) ->
				find = res.find -> it.idbatch is inc.idbatch
				if find then res.map (i) ->
					unless i.idbatch is inc.idbatch then i
					else _.assign i, jumlah: i.jumlah+1
				else res.push(inc) and res
			batches.reduce reducer, []
