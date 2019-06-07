if Meteor.isServer

	backup = (db_port, location) -> <[pasien gudang users rekap amprah]>map (i) ->
		shell.exec "mongoexport -h localhost:#db_port -d meteor -c #i -o #location/#{_.kebabCase hari new Date}-#i.json"

	Meteor.startup ->
		# new Meteor.Cron events: "0 0 * * *": backup 3001, '~/backup'

	Meteor.publish \coll, (name, sel = {}, opt = {}) ->
		coll[name]find sel, opt

	Meteor.publish \users, (sel = {}, opt = {}) ->
		Meteor.users.find sel, opt

	secureMethods = ({name, userId, args}) ->
		access = (group, role) -> if Meteor.users.findOne(userId)roles[group]
			(role in that) or that
		check = (obj, criteria) -> new SimpleSchema criteria .newContext!validate obj
		methods =
			newUser: -> ands arr =
				access \manajemen, \admin
				check args,
					username: type: String
					password: type: String
			addRole: -> ands arr =
				access \manajemen, \admin
				check args,
					id: type: String
					roles: type: String
					group: type: String, optional: true
					poli: type: String, optional: true
			rmRole: -> ands arr =
				access \manajemen, \admin
				check args, id: type: String
			rmRawat: -> ands arr =
				ors <[regis jalan]>map -> access it
				check args,
					idpasien: type: String
					idrawat: type: String
			updateArrayElm: -> ands arr =
				access \bayar
				check (_.omit args, \doc), _.merge {},
					... <[name scope recId elmId]>map ->
						"#it": type: String
		methods[name]!

	Meteor.methods do

		newUser: (doc) ->
			{username, password} = doc
			if secureMethods(name: \newUser, userId: this.userId, args: doc)
				if Accounts.findUserByUsername username
					for i in <[ username password ]>
						Accounts["set#{_.startCase i}"] that._id, doc[i]
				else Accounts.createUser doc

		addRole: (doc) ->
			{id, roles, group, poli} = doc
			if secureMethods(name: \addRole, userId: this.userId, args: doc)
				Roles.addUsersToRoles id, (poli or roles), group

		rmRole: (doc) ->
			if secureMethods(name: \rmRole, userId: this.userId, args: doc)
				Meteor.users.update {_id: doc.id}, $set: roles: {}

		import: ({name, selector, modifier, arrName}) ->
			find = coll[name]find selector
			if arrName
				if find then coll[name]update do
					{_id: find._id}, $push: "#that": modifier[that]0
				else coll[name]insert _.merge selector, modifier
			else coll[name]insert _.merge selector, modifier

		rmRawat: (doc) ->
			{idpasien, idrawat} = doc
			if secureMethods(name: \rmRawat, userId: this.userId, args: doc)
				coll.pasien.update idpasien, $set: rawat:
					coll.pasien.findOne(idpasien)rawat.filter ->
						it.idrawat isnt idrawat

		updateArrayElm: (obj) ->
			{name, scope, recId, elmId, doc} = obj
			if secureMethods(name: \updateArrayElm, userId: this.userId, args: obj)
				coll[name]update recId, $set: "#scope":
					coll[name]findOne(recId)[scope]map (i) ->
						if i["id#scope"] is elmId then doc else i

		serahObat: (doc) ->
			{_id, source, obat, bhp} = doc
			batches = []; opts = obat: \diapotik, depook: \didepook
			pasien = coll.pasien.findOne _id
			stock = opts[source]
			for i in [...obat, ...(bhp or [])]
				coll.gudang.update i.nama, $set: batch: reduce [],
					coll.gudang.findOne(i.nama)batch, (res, inc) -> arr =
						...res
						if i.jumlah < 1 then inc
						else
							minim = -> min [i.jumlah, inc[stock]]
							batches.push do
								idpasien: that._id if pasien
								nama_obat: i.nama
								idbatch: inc.idbatch
								nobatch: inc.nobatch
								jumlah: minim!
							obj = _.assign {}, inc, "#{stock}":
								inc[stock] - minim!
							i.jumlah -= minim!
							obj
			either = if _id then idpasien: _id else doc
			reduce [], batches, (res, inc) ->
				obj =
					nama_obat: inc.nama_obat
					idbatch: inc.idbatch
					nobatch: inc.nobatch
					jumlah: inc.jumlah
				if (res.find (i) -> i.no_mr is inc.no_mr)
					res.map (i) -> if i.no_mr is inc.no_mr
						obat: [...i.obat, obj]
				else [...res, obat: [obj]]
			.map (i) -> _.assign either, obat: reduce [], i.obat, (res, inc) ->
				obj = idbatch: inc.idbatch, nobatch: inc.nobatch, jumlah: inc.jumlah
				if (res.find (i) -> i.nama_obat is inc.nama_obat)
					res.map (i) -> _.assign i, batches: [...i.batches, obj]
				else [...res, nama_obat: inc.nama_obat, batches: [obj]]

		serahAmprah: (doc) ->
			{_id, nama, diserah, ruangan} = doc
			batches = []; cloned = _.merge {}, doc
			coll.gudang.update nama, $set: batch: reduce [],
				coll.gudang.findOne(nama)batch, (res, inc) -> arr =
					...res
					if diserah < 1 or inc.digudang < 1 then inc
					else
						minim = -> min [diserah, inc.digudang]
						batches.push do
							nama_obat: coll.gudang.findOne(nama)nama
							no_batch: inc.nobatch
							idbatch: inc.idbatch
							serah: minim!
						obj = _.assign {}, inc,
							digudang: inc.digudang - minim!
							if ruangan is \obat
								diapotik: inc[\diapotik] + minim!
							else if ruangan is \depook
								didepook: inc[\didepook] + minim!
						diserah -= minim!
						obj
			coll.amprah.update _id, _.assign doc,
				batch: batches, diserah: cloned.diserah
			batches

		doneRekap: ->
			sel = {printed: $exists: false}
			opt = {$set: printed: new Date!}
			coll.rekap.update sel, opt, multi: true

		sortByDate: ({idbarang}) ->
			coll.gudang.update idbarang, $set: batch: do ->
				source = coll.gudang.findOne idbarang .batch
				sortedIn = _.sortBy source, (i) -> new Date i.masuk .getTime!
				sortedEd = _.sortBy sortedIn, (i) -> new Date i.kadaluarsa .getTime!

		icdX: ({rawat, idpasien, icdx}) ->
			coll.pasien.update idpasien, $set: rawat:
				coll.pasien.findOne(idpasien)rawat.map (i) ->
					unless i.idrawat is rawat.idrawat then i
					else _.merge rawat, icdx: icdx

		onePasien: ({no_mr}) -> coll.pasien.findOne no_mr: +no_mr

		mergePatients: ->
			grouped = _.groupBy coll.pasien.find!fetch!, \no_mr
			filtered = _.filter grouped, -> it.length > 1
			merged = filtered.map -> _.merge ...it
			merged.map ->
				coll.pasien.remove no_mr: it.no_mr
				coll.pasien.insert it

		incomes: ({start, end}) -> if start < end
			a = coll.pasien.aggregate pipe =
				a = $match: rawat: $elemMatch: $and: [{tanggal: $gt: start}, {tanggal: $lt: end}]
				b = $unwind: \$rawat
				b = $match: $and: [{'rawat.tanggal': $gt: start}, {'rawat.tanggal': $lt: end}, {'rawat.cara_bayar': $eq: 1}]
			b = a.map (i) ->
				no_mr: zeros i.no_mr
				nama_pasien: i.regis.nama_lengkap
				tanggal: hari i.rawat.tanggal
				klinik: look(\klinik, i.rawat.klinik)label
				no_karcis: i.rawat.nobill.toString!
				tp_kartu: if i.rawat.first then 10000 else \-
				tp_karcis: look(\karcis, i.rawat.klinik)label*1000
				tp_tindakan: if i.rawat.tindakan then (_.sum that.map -> it.harga) else \-
				tp_obat: unless i.rawat.obat then \- else _.sum do
					coll.rekap.findOne(idrawat: i.rawat.idrawat)?obat.map (j) ->
						obat = coll.gudang.findOne j.nama_obat
						_.sum j.batches.map (k) -> (.jual * k.jumlah) obat.batch.find (l) -> l.idbatch is k.idbatch
			.map (i) -> _.assign i, total: i.tp_karcis + i.tp_tindakan + i.tp_obat
			jumlah = (type) -> rupiah _.sum b.map -> it[type]
			c = ['', '', '', '', 'Total', (jumlah \tp_kartu), (jumlah \tp_karcis), (jumlah \tp_tindakan), (jumlah \tp_obat), '']
			currencied = b.map (i) -> _.assign i,
				tp_kartu: rupiah i.tp_kartu
				tp_karcis: rupiah i.tp_karcis
				tp_tindakan: rupiah i.tp_tindakan
				tp_obat: rupiah i.tp_obat
				total: rupiah i.total
			[...currencied, c]

		dispenses: ({start, end, source}) -> if start < end
			a = coll.rekap.find!fetch!filter -> start < it.printed < end
			b = _.flattenDeep a.map (i) -> i.obat.map (j) -> j.batches.map (k) ->
				nama_obat: j.nama_obat, idbatch: k.idbatch, jumlah: k.jumlah
			c = reduce [], b, (res, inc) ->
				matched = -> _.every arr =
					it.nama_obat is inc.nama_obat
					it.idbatch is inc.idbatch
				unless (res.find -> matched it) then [...res, inc]
				else res.map -> unless matched(it) then it else
					_.assign it, jumlah: it.jumlah + inc.jumlah
			stokAwal = (i, source) -> _.sum (.map -> it.batch.serah) coll.amprah.aggregate pipe =
				a = $unwind: \$batch
				b = $match: $and: [{nama: i.nama_obat}, {ruangan: source}, {'batch.idbatch': i.idbatch}]
			d = c.map (i) -> _.merge i, awal: stokAwal i, source
			d.map (i) ->
				obj = coll.gudang.findOne i.nama_obat
				batch = obj.batch.find -> it.idbatch is i.idbatch
				'Nama Obat': obj.nama
				'Satuan': look(\satuan, obj.satuan)label
				'Jenis': look(\barang, obj.jenis)label
				'No. Batch': batch.nobatch
				'ED': hari batch.kadaluarsa
				'Harga': rupiah batch.jual
				'Barang Masuk': if start < batch.masuk < end then i.awal else \-
				'Qty Awal': if batch.masuk < start then i.awal else \-
				'Keluar': i.jumlah
				'Sisa Stok': i.awal - i.jumlah
				'Total Keluar': rupiah batch.jual * i.jumlah
				'Total Persediaan': rupiah batch.jual * (i.awal - i.jumlah)

		visits: ({start, end}) ->
			docs = coll.pasien.aggregate pipe =
				a = $match: rawat: $elemMatch: $and: list =
					{tanggal: $gt: start}
					{tanggal: $lt: end}
				b = $unwind: \$rawat
				c = $match: $and: x =
					{'rawat.tanggal': $gt: start}
					{'rawat.tanggal': $lt: end}
			docs.map (i) ->
				hari: moment i.rawat.tanggal .format 'D MMM YYYY'
				klinik: look \klinik, i.rawat.klinik .label
				cara_bayar: look \cara_bayar, i.rawat.cara_bayar .label
				baru_lama: \Lama
				pendaftar: _.startCase Meteor.users.findOne(i.rawat.petugas.regis)?username
				perawat: _.startCase Meteor.users.findOne(i.rawat.petugas.perawat)?username
				dokter: _.startCase Meteor.users.findOne(i.rawat.petugas.dokter)?username

		stocks: ({start, end}) ->
			a = coll.amprah.aggregate pipe =
				a = $match: tanggal_serah: $lt: end
				b = $unwind: \$batch
			b = reduce [], a, (res, inc) ->
				matched = -> _.every arr =
					it.nama is inc.nama
					it.batch.idbatch is inc.batch.idbatch
				unless (res.find -> matched it) then [...res, inc] else
					res.map -> unless matched(it) then it else
						_.assign it, batch: _.assign it.batch, serah: it.batch.serah + inc.batch.serah
			.map (i) ->
				obat = coll.gudang.findOne i.nama
				batch = obat.batch.find -> it.idbatch is i.batch.idbatch
				'Nama Obat': obat.nama
				'Satuan': look(\satuan, obat.satuan)label
				'Jenis': look(\barang, obat.jenis)label
				'No. Batch': batch.nobatch
				'ED': hari batch.kadaluarsa
				'Harga': rupiah batch.jual
				'Barang Masuk': if start < batch.masuk < end then batch.awal else \-
				'Stok Awal': if batch.masuk < start then batch.awal else \-
				'Keluar': i.batch.serah
				'Sisa Stok': batch.awal - i.batch.serah
				'Total Keluar': rupiah batch.jual * i.batch.serah
				'Total Persediaan': rupiah batch.jual * (batch.awal - i.batch.serah)

		notify: ({name, params}) ->
			obj =
				amprah: -> coll.amprah.find(diserah: $exists: false)fetch!length
				obat: -> (.length) coll.pasien.aggregate [$match: rawat: $elemMatch: givenDrug: $exists: false]
				depook: -> (.length) coll.pasien.aggregate [$match: rawat: $elemMatch: givenDrug: $exists: false]
				jalan: -> (.length) coll.pasien.aggregate pipe =
					a = $match: rawat: $elemMatch: $and: arr =
						{klinik: $eq: (.value) selects.klinik.find -> params.0 is _.snakeCase it.label}
						if params.1 then anamesa_dokter: $exists: false
						else anamesa_perawat: $exists: false
			obj[name]? ...params

		nextMR: ->
			list = coll.pasien.aggregate pipe =
				{$project: no_mr: 1}
				{$sort: no_mr: 1}
			nums = list.map -> it.no_mr
			index = nums.findIndex (i, j, k) -> i - k[j-1] > 1
			nums[index-1]+1

		backupNow: backup

		regions: ({provinsi, kabupaten, kecamatan, kelurahan}) ->
			if ands [provinsi, kabupaten, kecamatan, kelurahan]
				provinsi: (.daerah) coll.daerah.findOne provinsi: provinsi
				kabupaten: (.daerah) coll.daerah.findOne provinsi: provinsi, kabupaten: kabupaten
				kecamatan: (.daerah) coll.daerah.findOne kabupaten: kabupaten, kecamatan: kecamatan
				kelurahan: (.daerah) coll.daerah.findOne kecamatan: kecamatan, kelurahan: kelurahan
			else {}

		userProfile: (doc) -> Meteor.users.update doc.id, $set: profile: _.omit doc, \id
