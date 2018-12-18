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
			batches = []; pasien = coll.pasien.findOne _id
			for i in obat
				coll.gudang.update i.nama, $set: batch: reduce [],
					coll.gudang.findOne(i.nama)batch, (res, inc) -> arr =
						...res
						if i.jumlah < 1 then inc
						else
							minim = -> min [i.jumlah, inc.diapotik]
							batches.push do
								idpasien: pasien._id
								nama_obat: i.nama
								nobatch: inc.nobatch
								jumlah: minim!
							doc = _.assign {}, inc, diapotik:
								inc.diapotik - minim!
							i.jumlah -= minim!
							doc
			reduce [], batches, (res, inc) ->
				obj =
					nama_obat: inc.nama_obat
					nobatch: inc.nobatch
					jumlah: inc.jumlah
				if (res.find (i) -> i.idpasien is inc.idpasien)
					res.map (i) -> if i.idpasien is inc.idpasien
						idpasien: i.idpasien, obat: [...i.obat, obj]
				else [...res, idpasien: inc.idpasien, obat: [obj]]
			.map (i) -> _.assign i, obat: reduce [], i.obat, (res, inc) ->
				obj = nobatch: inc.nobatch, jumlah: inc.jumlah
				if (res.find (i) -> i.nama_obat is inc.nama_obat)
					res.map (i) -> _.assign i, batches: [...i.batches, obj]
				else [...res, nama_obat: inc.nama_obat, batches: [obj]]

		serahAmprah: (doc) ->
			coll.amprah.update doc._id, doc
			stock = if doc.ruangan is \obat then \digudang else \diapotik
			coll.gudang.update doc.nama, $set: batch: reduce [],
				coll.gudang.findOne(doc.nama)batch, (res, inc) -> arr =
					...res
					if doc.diserah < 1 or inc[stock] < 1 then inc
					else
						minim = -> min [doc.diserah, inc[stock]]
						obj = _.assign {}, inc,
							"#stock": inc[stock] - minim!
							if stock is \digudang then diapotik:
								inc[\diapotik] + minim!
						doc.diserah -= minim!
						obj

		doneRekap: ->
			sel = {printed: $exists: false}
			opt = {$set: printed: new Date!}
			coll.rekap.update sel, opt, multi: true

		sortByDate: (idbarang) ->
			coll.gudang.update idbarang, $set: batch: do ->
				source = coll.gudang.findOne idbarang .batch
				sortedIn = _.sortBy source, (i) -> new Date i.masuk .getTime!
				sortedEd = _.sortBy sortedIn, (i) -> new Date i.kadaluarsa .getTime!

		icdX: ({rawat, pasien, icdx}) ->
			coll.pasien.update pasien._id, $set: rawat:
				coll.pasien.findOne(pasien._id)rawat.map (i) ->
					unless i.idrawat is rawat.idrawat then i
					else _.merge rawat, icdx: icdx

		onePasien: -> coll.pasien.findOne no_mr: +it
