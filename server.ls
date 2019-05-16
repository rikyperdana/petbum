if Meteor.isServer

	backup = (db_port, location) -> <[pasien gudang users rekap amprah]>map (i) ->
		shell.exec "mongoexport -h localhost:#db_port -d meteor -c #i -o #location/#{_.kebabCase hari new Date}-#i.json"

	Meteor.startup ->
		# new Meteor.Cron events: "0 0 * * *": backup 3001, '~/backup'

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

		serahObat: (doc) ->
			batches = []; opts = obat: \diapotik, depook: \didepook
			pasien = coll.pasien.findOne doc._id
			stock = opts[doc.source]
			for i in doc.obat
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
							doc = _.assign {}, inc, "#{stock}":
								inc[stock] - minim!
							i.jumlah -= minim!
							doc
			either = if doc._id then idpasien: doc._id else doc
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
			batches = []
			coll.gudang.update doc.nama, $set: batch: reduce [],
				coll.gudang.findOne(doc.nama)batch, (res, inc) -> arr =
					...res
					if doc.diserah < 1 or inc.digudang < 1 then inc
					else
						minim = -> min [doc.diserah, inc.digudang]
						batches.push do
							nama_obat: coll.gudang.findOne(doc.nama)nama
							no_batch: inc.nobatch
							idbatch: inc.idbatch
							serah: minim!
						obj = _.assign {}, inc,
							digudang: inc.digudang - minim!
							if doc.ruangan is \obat
								diapotik: inc[\diapotik] + minim!
							else if doc.ruangan is \depook
								didepook: inc[\didepook] + minim!
						doc.diserah -= minim!
						obj
			coll.amprah.update doc._id, _.merge doc, batch: batches
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

		incomes: (start, end) -> if start < end
			a = coll.pasien.aggregate pipe =
				a = $match: rawat: $elemMatch: $and: [{tanggal: $gt: start}, {tanggal: $lt: end}]
				b = $unwind: \$rawat
				b = $match: $and: [{'rawat.tanggal': $gt: start}, {'rawat.tanggal': $lt: end}, {'rawat.cara_bayar': $eq: 1}]
			b = a.map (i) ->
				no_mr: zeros i.no_mr
				nama_pasien: i.regis.nama_lengkap
				tanggal: hari i.rawat.tanggal
				klinik: look(\klinik, i.rawat.klinik)label
				tp_kartu: if i.rawat.first then 10000 else \-
				tp_karcis: look(\karcis, i.rawat.klinik)label*1000
				tp_tindakan: if i.rawat.tindakan then (_.sum that.map -> it.harga) else \-
				tp_obat: unless i.rawat.obat then \- else _.sum do
					coll.rekap.findOne(idrawat: i.rawat.idrawat)?obat.map (j) ->
						obat = coll.gudang.findOne j.nama_obat
						_.sum j.batches.map (k) -> (.jual) obat.batch.find (l) -> l.idbatch is k.idbatch
				no_karcis: i.rawat.nobill.toString!
			jumlah = (type) -> rupiah _.sum b.map -> it[type]
			c = ['', '', '', 'Total', (jumlah \tp_kartu), (jumlah \tp_karcis), (jumlah \tp_tindakan), (jumlah \tp_obat), '']
			currencied = b.map -> _.assign it,
				tp_kartu: rupiah it.tp_kartu
				tp_karcis: rupiah it.tp_karcis
				tp_tindakan: rupiah it.tp_tindakan
				tp_obat: rupiah it.tp_obat
			d = [...currencied, c]

		dispenses: (start, end) -> if start < end
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
			c.map (i) -> _.merge i,
				awal_farmasi: (.awal) coll.gudang.findOne(i.nama_obat)batch.find -> it.idbatch is i.idbatch
				awal_apotik: (?diserah) coll.amprah.findOne ruangan: \obat, nama: i.nama_obat
				awal_depook: (?diserah) coll.amprah.findOne ruangan: \depook, nama: i.nama_obat
			/* d = c.map (i) ->
				obj = coll.gudang.findOne i.nama_obat
				price = (.beli) obj.batch.find -> it.idbatch is i.idbatch
				awal = _.sum obj.batch.map ->
					if it.idbatch is i.idbatch then it.awal
				batch = (idbatch) -> obj.batch.find -> it.idbatch is idbatch
				'Nama Obat': obj.nama
				'Satuan': look(\satuan, obj.satuan)label
				'Jenis': look(\barang, obj.jenis)label
				'No. Batch': i.no_batch
				'ED': hari batch(i.idbatch)kadaluarsa
				'Harga': rupiah price
				'Barang Masuk': if start < batch(i.idbatch)masuk < end then awal else ''
				'Qty Awal': if batch(i.idbatch)masuk < start then awal else ''
				'Keluar': i.jumlah
				'Sisa Stok': awal - i.jumlah
				'Total Keluar': rupiah price * i.jumlah
				'Total Persediaan': rupiah price * (awal - i.jumlah) */

		visits: (start, end) ->
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

		backupNow: backup

		regions: ({provinsi, kabupaten, kecamatan, kelurahan}) ->
			if ands [provinsi, kabupaten, kecamatan, kelurahan]
				provinsi: (.daerah) coll.daerah.findOne provinsi: provinsi
				kabupaten: (.daerah) coll.daerah.findOne provinsi: provinsi, kabupaten: kabupaten
				kecamatan: (.daerah) coll.daerah.findOne kabupaten: kabupaten, kecamatan: kecamatan
				kelurahan: (.daerah) coll.daerah.findOne kecamatan: kecamatan, kelurahan: kelurahan
			else {}

		userProfile: (doc) -> Meteor.users.update doc.id, $set: profile: _.omit doc, \id
