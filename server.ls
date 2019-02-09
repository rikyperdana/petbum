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
			batches = []
			stock = if doc.ruangan is \obat then \digudang else \diapotik
			coll.gudang.update doc.nama, $set: batch: reduce [],
				coll.gudang.findOne(doc.nama)batch, (res, inc) -> arr =
					...res
					if doc.diserah < 1 or inc[stock] < 1 then inc
					else
						minim = -> min [doc.diserah, inc[stock]]
						batches.push do
							nama_obat: coll.gudang.findOne(doc.nama)nama
							no_batch: inc.nobatch
							serah: minim!
						obj = _.assign {}, inc,
							"#stock": inc[stock] - minim!
							if stock is \digudang then diapotik:
								inc[\diapotik] + minim!
						doc.diserah -= minim!
						obj
			batches

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

		mergePatients: ->
			grouped = _.groupBy coll.pasien.find!fetch!, \no_mr
			filtered = _.filter grouped, -> it.length > 1
			merged = filtered.map -> _.merge ...it
			merged.map ->
				coll.pasien.remove no_mr: it.no_mr
				coll.pasien.insert it

		incomes: (start, end) -> if start < end then _.compact _.flattenDeep do
			coll.pasien.find!fetch!map (i) -> i.rawat?map (j) ->
				conds = ands arr =
					start < j.tanggal < end
					j.status_bayar or j.billRegis
				card = if i.rawat.length > 1 then 10000 else false
				'NO. MR': i.no_mr
				'NAMA PASIEN': i.regis.nama_lengkap
				'TANGGAL': hari j.tanggal
				'JENIS PEMBAYARAN': (.join ' + ') _.compact arr =
					\Regis
					\Kartu if card
					\Tindakan if j.tindakan
				'KLINIK': look \klinik, j.klinik .label
				'NO.KARCIS': j.nobill
				'JUMLAH (Rp)': _.sum arr =
					card
					look(\karcis, j.klinik)label*1000
					_.sum j.tindakan?map (k) ->
						look2(\tarif, k.nama)harga

		dispenses: (start, end) -> if start < end
			getPrice = (nama_obat, no_batch) ->
				coll.gudang.findOne(nama_obat)
				.batch.find(-> it.nobatch is no_batch)
				.beli
			a = coll.rekap.find!fetch!filter -> start < it.printed < end
			b = _.flattenDeep a.map (i) -> i.obat.map (j) -> j.batches.map (k) ->
				nama_obat: j.nama_obat, no_batch: k.nobatch, jumlah: k.jumlah
			c = reduce [], b, (res, inc) ->
				matched = -> _.every arr =
					it.nama_obat is inc.nama_obat
					it.no_batch is inc.no_batch
				unless (res.find -> matched it) then [...res, inc]
				else res.map -> unless matched(it) then it else
					_.assign it, jumlah: it.jumlah + inc.jumlah
			d = c.map (i) ->
				price = getPrice i.nama_obat, i.no_batch
				obj = coll.gudang.findOne i.nama_obat
				awal = _.sum obj.batch.map ->
					if it.nobatch is i.no_batch then it.awal
				'Nama Obat': obj.nama
				'No. Batch': i.no_batch
				'Jumlah': i.jumlah
				'Harga': price
				'Total': price * i.jumlah
				'Stok Awal': awal
				'Stok Akhir': awal - i.jumlah

		visits: (start, end) ->
			docs = coll.pasien.aggregate pipe =
				a = $match: rawat: $elemMatch: $and: list =
					{tanggal: $gt: start}
					{tanggal: $lt: end}
				b = $unwind: \$rawat
				c = $match: $and: x =
					{'rawat.tanggal': $gt: start}
					{'rawat.tanggal': $lt: end}
			maped = docs.map (i) -> _.merge {},
				hari: moment i.rawat.tanggal .format 'D MMM YYYY'
				... <[tanggal klinik cara_bayar]>map (j) -> "#j": i.rawat[j]
			grouped = _.groupBy maped, \hari
			result = _.map grouped, (val, key) ->
				hari: key, tanggal: (new Date key),
				poli: _.merge ... selects.klinik.map (v, k) ->
					"#{v.label}": (.length) val.filter -> it.klinik is k+1
				bayar: _.merge ... selects.cara_bayar.map (v, k) ->
					"#{v.label}": (.length) val.filter -> it.cara_bayar is k+1
				status: _.merge ... [
					{Baru: (.length) val.filter -> it.baru}
					{Lama: val.length - (.length) val.filter -> it.baru}
				]
			_.sortBy result, \tanggal

		stocks: (start, end) ->
			coll.gudang.aggregate pipe =
				a = $match: batch: $elemMatch: $and: arr =
					{masuk: $gt: start}
					{masuk: $lt: end}
				b = $unwind: \$batch
				c = $match: $and: arr =
					{'batch.masuk': $gt: start}
					{'batch.masuk': $lt: end}
			.map (i) ->
				'Nama Obat': i.nama
				'Kemasan': look(\satuan, i.satuan)label
				'Satuan': look(\satuan, i.satuan)label
				'Jenis': look(\barang, i.jenis)label
				'Batch': i.batch.nobatch
				'ED': hari i.batch.kadaluarsa
				'Harga Satuan': rupiah i.batch.beli
				'Stok Awal': i.batch.awal.toString!
				'Sisa Stock': i.batch.digudang.toString!
				'Total Nilai': rupiah i.batch.digudang * i.batch.beli

		notify: (name) ->
			obj = amprah: -> coll.amprah.find(diserah: $exists: false)fetch!length
			obj[name]?!

		nextMR: ->
			list = coll.pasien.aggregate pipe =
				{$project: no_mr: 1}
				{$sort: no_mr: 1}
			nums = list.map -> it.no_mr
			index = nums.findIndex (i, j, k) -> i - k[j-1] > 1
			nums[index-1]+1
