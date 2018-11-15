if Meteor.isClient

	attr =
		layout: rights: -> modules.filter -> it.name in
			_.flatMap (_.keys Meteor.user!?roles), (i) ->
				(.list) rights.find -> it.group is i
		pasien:
			showForm:
				patient: onclick: ->
					state.showAddPatient = not state.showAddPatient
				rawat: onclick: ->
					state.showAddRawat = not state.showAddRawat
			headers:
				patientList: <[ tanggal nama_lengkap tanggal_lahir tempat_lahir poliklinik ]>
				rawatFields: <[ tanggal klinik cara_bayar bayar_pendaftaran status_bayar cek ]>
				icdFields: <[ nama_pasien tanggal klinik dokter diagnosis nama_perawat cek ]>
			rawatDetails: (doc) -> arr =
				{head: \Tanggal, cell: hari doc.tanggal}
				{head: \Klinik, cell: look(\klinik, doc.klinik)label}
				{head: 'Cara Bayar', cell: look(\cara_bayar, doc.cara_bayar)label}
				{head: 'Anamesa Perawat', cell: doc?anamesa_perawat}
				{head: 'Anamesa Dokter', cell: doc?anamesa_dokter}
				{head: \Diagnosa, cell: doc?diagnosa}
				{head: \Planning, cell: doc?planning}
			poliFilter: (arr) -> if arr then _.compact arr.map (i) ->
				if userRole! is _.snakeCase look(\klinik, i.klinik)label then i
				else if \regis is userGroup! then i
			ownKliniks: -> roles!?jalan?map (i) ->
				(.value) selects.klinik.find (j) -> i is _.snakeCase j.label
			lastKlinik: (arr) -> unless roles!?jalan then arr else
				notHandled = (name, doc) -> ands arr =
					not (_.last doc.rawat)[name]
					0 is dayDiff (.tanggal) _.last doc.rawat
				if isDr! then arr.filter -> notHandled \anamesa_dokter, it
				else arr.filter -> notHandled \anamesa_perawat, it
		bayar: header: <[ no_mr nama tanggal cara_bayar klinik aksi ]>
		apotik: header: <[ no_mr nama tanggal total_biaya cara_bayar klinik aksi ]>
		gudang: headers:
			farmasi: <[ jenis_barang nama_barang stok_gudang stok_diapotik hapus ]>
			rincian: <[ nobatch digudang diapotik masuk kadaluarsa ]>
		farmasi: fieldSerah: <[ nama_obat jumlah_obat aturan_kali aturan_dosis ]>
		manajemen: headers: tarif: <[ nama jenis harga grup active ]>
		amprah: headers: requests: <[ ruangan peminta jumlah nama_barang penyerah diserah ]>

	comp =
		layout: (comp) ->
			view: -> m \div,
				unless Meteor.userId! then m.route.set \/login
				m \link, rel: \stylesheet, href: 'https:/maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css'
				m \nav.navbar.is-info,
					role: \navigation, 'aria-label': 'main navigation',
					m \.navbar-brand, m \a.navbar-item, href: \#,
						_.upperCase (?full or \RSPB) modules.find ->
							it.name is m.route.get!split(\/)[1]
					m \.navbar-end, m \.navbar-item.has-dropdown,
						class: \is-active if state.userMenu
						m \a.navbar-link,
							onclick: -> state.userMenu = not state.userMenu
							m \span, Meteor.user!?username
						m \.navbar-dropdown.is-right, do ->
							arr =
								[JSON.stringify Meteor.user!?roles]
								[\Login, -> m.route.set \/login]
								[\Logout, -> [
									Meteor.logout!
									(m.route.set \/login)
									m.redraw!
								]]
							arr.map (i) -> m \a.navbar-item,
								onclick: i?1, i.0
				m \.columns,
					oncreate: -> Meteor.subscribe \users, onReady: -> m.redraw!
					Meteor.userId! and m \.column.is-2, m \aside.menu.box,
						m \p.menu-label, 'Admin Menu'
						m \ul.menu-list, attr.layout.rights!map (i) ->
							m \li, m "a##{i.name}",
								href: "/#{i.name}"
								class: \is-active if state.activeMenu is i.name
								m \span, _.startCase i.full
								if \regis is currentRoute! then m \ul,
									[[\baru, 'Pasien Baru'], [\lama, 'Cari Pasien']]map (i) ->
										m \li, m \a, href: "/regis/#{i.0}", oncreate: m.route.link, i.1
								if same \manajemen, currentRoute!, i.name
									m \ul, <[ users imports ]>map (i) -> m \li, m \a,
										href: "/manajemen/#i", oncreate: m.route.link,
										m \span, _.startCase i
					m \.column, if comp then m that
		login: -> view: -> m \.container,
			m \.content, m \h5, \Login
			m \form,
				onsubmit: (e) ->
					e.preventDefault!
					vals = _.initial _.map e.target, -> it.value
					Meteor.loginWithPassword ...vals, (err) ->
						if err
							state.error = 'Salah Password atau Username'
							m.redraw!
						else m.route.set \/dashboard
				m \input.input, type: \text, placeholder: \Username
				m \input.input, type: \password, placeholder: \Password
				m \input.button.is-success, type: \submit, value: \Login
				if state.error then m \article.message, m \.message-header,
					(m \p, that), m \button.delete, 'aria-label': \delete
		welcome: -> view: -> m \.content,
			m \h1, \Panduan
			m \p, 'Selamat datang di SIMRSPB 2018'
		pasien: -> view: -> m \.content,
			if m.route.param(\jenis) in <[baru edit]> then m autoForm do
				collection: coll.pasien
				schema: new SimpleSchema schema.regis
				type: if m.route.param(\idpasien) then \update else \insert
				id: \formRegis
				doc: coll.pasien.findOne!
				buttonContent: \Simpan
				columns: 3
				hooks:
					before: (doc, cb) ->
						cb _.merge doc, regis: petugas:
							"#{userGroup!}": Meteor.userId!
					after: (id) ->
						state.showAddPatient = null
						m.route.set "/regis/lama/#id"
			if userRole(\mr) then m \div,
				m \br
				m \form.columns,
					onsubmit: (e) ->
						e.preventDefault!
						Meteor.call \onePasien, e.target.0.value, (err, res) ->
							makePdf.icdx res if res
					m \.column, m \input.input, type: \text, placeholder: 'No MR Pasien'
					m \.column, m \input.button.is-primary, type: \submit, value: \Unduh
				m \h5, 'Kodifikasi ICD 10'
				m \table.table,
					oncreate: -> Meteor.subscribe \coll, \pasien,
						{rawat: $elemMatch: $and: [
							{'anamesa_dokter': $exists: true}
							{icdx: $exists: false}
						]}
						onReady: -> m.redraw!
					m \thead, attr.pasien.headers.icdFields.map (i) -> m \th, _.startCase i
					m \tbody, coll.pasien.find!fetch!map (i) -> i.rawat.map (j) ->
						if j.anamesa_dokter and not j.icdx then m \tr, tds arr =
							i.regis.nama_lengkap
							hari j.tanggal
							look(\klinik, j.klinik)label
							\-
							j.diagnosa?0
							\-
							m \.button.is-info,
								onclick: -> state.modal = _.merge rawat: j, pasien: i
								m \span, \Cek
				if state.modal then elem.modal do
					title: 'Kodekan ICD 10'
					content: m \div,
						m \table.table, that.rawat.diagnosa.map (i, j) ->
							m \tr, [(m \td, j+1), (m \td, _.startCase i)]
						m autoForm do
							schema: new SimpleSchema icdx: type: [String]
							type: \method
							meteormethod: \icdX
							hooks:
								before: (doc, cb) ->
									cb _.merge {}, state.modal, doc
								after: ->
									state.modal = null
									m.redraw!
			else if m.route.get! in ['/regis/lama', '/jalan'] then m \div,
				m \form,
					onsubmit: (e) ->
						e.preventDefault!
						if e.target.0.value.length > 3
							byName = 'regis.nama_lengkap':
								$options: \-i, $regex: ".*#{e.target.0.value}.*"
							byNoMR = no_mr: +e.target.0.value
							Meteor.subscribe \coll, \pasien, {$or: [byName, byNoMR]},
								onReady: -> m.redraw!
					m \input.input, type: \text, placeholder: \Pencarian
				m \table.table,
					oncreate: -> Meteor.subscribe \users, onReady: ->
						onKlinik = rawat: $elemMatch: klinik: $in: attr.pasien.ownKliniks!
						Meteor.subscribe \coll, \pasien, onKlinik, onReady: -> m.redraw!
					m \thead, m \tr, attr.pasien.headers.patientList.map (i) ->
						m \th, _.startCase i
					m \tbody, attr.pasien.lastKlinik(coll.pasien.find!fetch!)map (i) ->
						rows = -> m \tr,
							ondblclick: -> m.route.set "#{m.route.get!}/#{i._id}"
							tds arr =
								if i.rawat?[i.rawat?length-1]?tanggal then hari that
								i.regis.nama_lengkap
								if i.regis.tgl_lahir then moment(that)format 'D MMM YYYY'
								if i.regis.tmpt_lahir then _.startCase that
								_.startCase userRole!
						if currentRoute! is \jalan
							if i.rawat?reverse!?0?billRegis then rows!
						else rows!
				if userGroup(\jalan) and !isDr! then m \div,
					m \h5, 'Daftar Antrian Panggilan Dokter'
					m \table.table,
						m \thead, m \tr, attr.pasien.headers.patientList.map (i) ->
							m \th, _.startCase i
						m \tbody, coll.pasien.find!fetch!map (i) ->
							doneByNurse = -> ands arr =
								i.rawat[i.rawat.length-1]anamesa_perawat
								not i.rawat[i.rawat.length-1]anamesa_dokter
							if doneByNurse! then m \tr, tds arr =
								hari i.rawat[i.rawat.length-1]tanggal
								i.regis.nama_lengkap
								hari i.regis.tgl_lahir
								i.regis.tmpt_lahir
								_.startCase userRole!
			else if m.route.param \idpasien then m \div,
				oncreate: ->
					Meteor.subscribe \coll, \tarif
					Meteor.subscribe \coll, \gudang
					Meteor.subscribe \coll, \pasien,
						{_id: m.route.param \idpasien}, onReady: -> m.redraw!
					isDr! and Meteor.subscribe \users, username: $options: \-i, $regex: '^dr'
				m \.content, m \h5, 'Rincian Pasien'
				if coll.pasien.findOne m.route.param \idpasien then m \div,
					m \table.table, [
						[
							{name: 'No. MR', data: that.no_mr}
							{name: 'Tanggal Lahir', data: hari that.regis.tgl_lahir}
						]
					,
						[
							{name: 'Nama Lengkap', data: _.startCase that.regis.nama_lengkap}
							{name: 'Tempat Lahir', data: _.startCase that.regis.tmpt_lahir}
						]
					,
						[
							{name: 'Tempat Tinggal', data: _.startCase that.regis.alamat}
							{name: 'Umur', data: moment!diff(that.regis.tgl_lahir, \years) + ' tahun'}
						]
					]map (i) -> m \tr, i.map (j) -> [(m \th, j.name), (m \td, j.data)]
					if currentRoute! is \regis then m \div,
						m \.button.is-info,
							onclick: -> makePdf.card!
							m \span, \Kartu
						m \.button.is-info,
							onclick: -> makePdf.consent!
							m \span, \Consent
						m \.button.is-warning,
							onclick: -> m.route.set "/regis/edit/#{m.route.param \idpasien}"
							m \span, \Edit
						m \.button.is-success, attr.pasien.showForm.rawat, \+Rawat
					state.showAddRawat and m autoForm do
						collection: coll.pasien
						schema: new SimpleSchema schema.rawatRegis
						type: \update-pushArray
						id: \formJalan
						scope: \rawat
						doc: that
						buttonContent: \Tambahkan
						columns: 3
						hooks:
							before: (doc, cb) ->
								cb _.merge doc, petugas: "#{userGroup!}": Meteor.userId!
							after: ->
								state.showAddRawat = false
								m.redraw!
					[til 2]map -> m \br
					state.docRawat and m \.content,
						m \h5, 'Rincian Rawat'
						m \table.table,
							attr.pasien.rawatDetails that.rawat.find(-> it.idrawat is state.docRawat)
							.map (i) -> i.cell and m \tr, [(m \th, i.head), (m \td, i.cell)]
					state.docRawat and m autoForm do
						collection: coll.pasien
						schema: new SimpleSchema do
							if isDr! then schema.rawatDoctor
							else schema.rawatNurse
						type: \update-pushArray
						id: \formNurse
						scope: \rawat
						doc: that
						buttonContent: 'Simpan'
						columns: 3
						hooks:
							before: (doc, cb) -> Meteor.call \rmRawat, that._id, state.docRawat,
								(err, res) -> res and cb _.merge doc.rawat.0,
									(that.rawat.find -> it.idrawat is state.docRawat),
									status_bayar: true if ands arr =
										doc.rawat.0.obat
										not doc.rawat.0.tindakan
									petugas: "#{if isDr! then \dokter else \perawat}": Meteor.userId!
							after: ->
								state.docRawat = null
								m.redraw!
					m \table.table,
						m \thead, m \tr, attr.pasien.headers.rawatFields.map (i) ->
							m \th, _.startCase i
						m \tbody, attr.pasien.poliFilter(that?rawat?reverse!)?map (i) -> m \tr, [
							hari i.tanggal
							look(\klinik, i.klinik)label
							look(\cara_bayar, i.cara_bayar)label
							... <[ billRegis status_bayar ]>map ->
								if i[it] then \Sudah else \Belum
							if \jalan is userGroup! then m \button.button.is-info,
								onclick: -> state.modal = i
								m \span, \Cek
						]map (j) -> m \td, j
					if state.modal then elem.modal do
						title: 'Rincian rawat'
						content: m \div,
							m \h1, coll.pasien.findOne!regis.nama_lengkap
							m \table.table,
								attr.pasien.rawatDetails state.modal
								.map (i) -> i.cell and m \tr, [(m \th, i.head), (m \td, i.cell)]
							if state.modal.tindakan then m \div,
								m \br
								m \table, m \tr, m \th, \Tindakan
								m \table.table,
									that?map (i) -> m \tr, tds arr =
										_.startCase look2(\tarif, i.nama)nama
										rupiah i.harga
									m \tr, (m \th, \Total), m \td,
										rupiah _.sum that.map -> it.harga
							if state.modal.obat then m \div,
								m \br
								m \table, m \tr, m \th, \Obat
								m \table.table, that.map (i) -> m \tr, tds arr =
									_.startCase look2(\gudang, i.nama)nama
									"#{i.aturan.kali} kali"
									"#{i.aturan.dosis} dosis"
									"#{i.jumlah} unit"
									if i.puyer then "puyer #that"
						confirm: \Lanjutkan if ands arr =
							currentRoute! is \jalan
							if !isDr! then !state.modal.anamesa_perawat else true
							if isDr! then state.modal.anamesa_perawat else true
							if isDr! then !state.modal.anamesa_dokter else true
						action: ->
							state.docRawat = state.modal.idrawat
							state.spm = new Date!
							state.modal = null
			else m \div
		regis: -> this.pasien
		jalan: -> this.pasien
		bayar: -> view: -> m \.content,
			m \table.table,
				oncreate: ->
					Meteor.subscribe \coll, \tarif
					Meteor.subscribe \coll, \pasien,
						{rawat: $elemMatch: $or: [
							{billRegis: $ne: true}
							{status_bayar: $ne: true}
						]}
						onReady: -> m.redraw!
					coll.pasien.find!observe changed: -> m.redraw!
				m \thead, m \tr, attr.bayar.header.map (i) -> m \th, _.startCase i
				m \tbody, coll.pasien.find!fetch!map (i) -> _.compact i.rawat.map (j) ->
					conds = ors arr =
						not j.billRegis
						if j.tindakan then not j.status_bayar
					if j.cara_bayar is 1 then if conds then m \tr, [
						i.no_mr, i.regis.nama_lengkap,
						hari j.tanggal
						look(\cara_bayar, j.cara_bayar)label
						look(\klinik, j.klinik)label
						m \a.button.is-success,
							onclick: -> state.modal = _.merge j, pasienId: i._id
							m \span, \Bayar
					]map (k) -> m \td, k
			if state.modal
				tindakans = state.modal.tindakan?map -> arr =
					_.startCase look2(\tarif, it.nama)nama
					it.harga
				uraian =
					['Cetak Kartu', 10000] unless coll.pasien.findOne(state.modal.pasienId)rawat?0?billRegis
					['Daftar Rawat', 30000] unless state.modal.billRegis
					... tindakans or []
				params = <[ pasienId idrawat ]>map -> state.modal[it]
				elem.modal do
					title: 'Sudah bayar?'
					content: m \table.table,
						uraian.map (i) -> if i then m \tr, [(m \th, i.0), (m \td, rupiah i.1)]
						m \tr, [(m \th, 'Total Biaya'), (m \td, rupiah _.sum uraian.map -> it?1)]
					confirm: \Sudah
					action: ->
						Meteor.call \updateArrayElm,
							name: \pasien, recId: that.pasienId,
							scope: \rawat, elmId: that.idrawat, doc: _.merge that,
								if !that.billRegis then billRegis: true
								else if !that.status_bayar then status_bayar: true
						unless that.anamesa_perawat
							makePdf.payRegCard ...params, _.compact uraian
						else makePdf.payRawat ...params, _.compact uraian
						state.modal = null
						m.redraw!
		obat: -> view: -> m \.content,
			m \h5, \Apotik,
			m \table.table,
				oncreate: ->
					Meteor.subscribe \coll, \rekap, printed: $exists: false
					Meteor.subscribe \coll, \pasien,
						{rawat: $elemMatch: obat: $elemMatch: hasil: $exists: false}
						onReady: -> m.redraw!
				m \thead, attr.apotik.header.map (i) -> m \th, _.startCase i
				m \tbody, coll.pasien.find!fetch!map (i) ->
					i.rawat.map (j) -> j.obat?map (k) ->
						okay = ->
							if j.cara_bayar is 1 then !k.hasil and j.status_bayar
							else !	k.hasil
						okay! and m \tr, tds arr =
							i.no_mr
							i.regis.nama_lengkap
							hari j.tanggal
							\-
							look(\cara_bayar, j.cara_bayar)label
							look(\klinik, j.klinik)label
							m \.button.is-success,
								onclick: -> state.modal = _.merge k, j, i
								m \span, \Serah
			if state.modal then elem.modal do
				title: 'Serahkan Obat?'
				content: m \table.table,
					oncreate: -> Meteor.subscribe \coll, \gudang,
						onReady: -> m.redraw!
					m \tr, attr.farmasi.fieldSerah.map (i) ->
						m \th, _.startCase i
					m \tr, tds arr =
						look2(\gudang, state.modal.nama)?nama
						"#{state.modal.jumlah} unit"
						"#{state.modal.aturan.kali} kali sehari"
						"#{state.modal.aturan.dosis} unit per konsumsi"
				confirm: \Serahkan
				action: ->
					Meteor.call \serahObat, state.modal, (err, res) -> if res
						coll.pasien.update state.modal._id, $set: rawat:
							coll.pasien.findOne(state.modal._id)rawat.map (i) ->
								if i.idrawat is state.modal.idrawat
									_.assign i, obat: i.obat.map ->
										_.merge it, hasil: true
								else i
						coll.rekap.insert batches: res
						state.modal = null
						m.redraw!
			m \.button.is-warning,
				onclick: -> makePdf.rekap!
				m \span, 'Cetak Rekap'
		farmasi: -> view: -> m \.content,
			unless m.route.param(\idbarang) then m \div,
				m \form,
					onsubmit: (e) ->
						e.preventDefault!
						if e.target.0.value.length > 3 then Meteor.subscribe \coll, \gudang,
							{nama: $options: \-i, $regex: ".*#{e.target.0.value}.*"}
							onReady: -> m.redraw!
					m \input.input, type: \text, placeholder: \Pencarian
				if roles!?farmasi then m \button.button.is-success,
					onclick: -> state.showForm = not state.showForm
					m \span, '+Tambah Jenis Obat'
				if state.showForm
					m \h5, 'Form Barang Farmasi'
					m autoForm do
						collection: coll.gudang
						schema: new SimpleSchema schema.farmasi
						type: \insert
						id: \formFarmasi
						buttonContent: \Simpan
						columns: 3
						hooks: after: ->
							state.showForm = null
							m.redraw!
				m \table.table,
					# oncreate: -> Meteor.subscribe \coll, \gudang, onReady: -> m.redraw!
					m \thead, m \tr, attr.gudang.headers.farmasi.map (i) ->
						m \th, _.startCase i
					m \tbody, coll.gudang.find!fetch!map (i) -> m \tr,
						ondblclick: -> m.route.set "/farmasi/#{i._id}"
						m \td, look(\barang, i.jenis)label
						m \td, i.nama
						<[ digudang diapotik ]>map (j) ->
							m \td, _.sumBy i.batch, j
						userRole! is \admin and m \td, m \.button.is-danger,
							onclick: -> state.modal = i
							m \span, \Hapus
					if state.modal then elem.modal do
						title: 'Yakin hapus Obat ini?'
						confirm: \Yakin
						action: -> coll.gudang.remove _id: state.modal._id
			else m \div,
				oncreate: -> Meteor.subscribe do
					\coll, \gudang,
					_id: m.route.param \idbarang
					onReady: -> m.redraw!
				m \h5, 'Rincian Obat'
				m \table.table,
					if coll.gudang.findOne! then [
						[
							{name: 'Nama Barang', cell: that.nama}
							{name: 'Jenis Barang', cell: look(\barang, that.jenis)label}
						]
					,
						[
							{name: \Kandungan, cell: that.kandungan}
							{name: \Satuan, cell: look(\satuan, that.satuan)label}
						]
					]map (i) -> m \tr, i.map (j) -> [(m \th, j.name), (m \td, j.cell)]
				if roles!?farmasi then m \.button.is-warning,
					onclick: -> state.showForm = not state.showForm
					m \span,'Tambahkan Batch'
				if state.showForm then m autoForm do
					collection: coll.gudang
					schema: new SimpleSchema schema.farmasi
					type: \update-pushArray
					scope: \batch
					doc: coll.gudang.findOne!
					id: \formTambahObat
					buttonContent: \Tambahkan
					columns: 3
					hooks: after: ->
						Meteor.call \sortByDate, m.route.param \idbarang
						state.showForm = null
						m.redraw!
				m \table.table,
					m \thead, attr.gudang.headers.rincian.map (i) ->
						m \th, _.startCase i
					m \tbody, coll.gudang.findOne!?batch.map (i) -> m \tr, [
						i.nobatch, i.digudang, i.diapotik,
						(hari i.masuk), (hari i.kadaluarsa)
					]map (j) -> m \td, j
		manajemen: -> view: ->
			if \users is m.route.param \subroute then m \.content,
				oncreate: -> Meteor.subscribe \users, onReady: -> m.redraw!
				m \h1, 'Manajemen Pengguna'
				m \h5, 'Tambahkan pengguna baru'
				m \form,
					onsubmit: (e) ->
						e.preventDefault!
						vals = _.initial _.map e.target, -> it.value
						if vals.1 is vals.2 then Meteor.call \newUser,
							{username: vals.0, password: vals.1}
							(err, res) -> res and m.redraw!
					[
						{type: \text, place: \Username}
						{type: \password, place: \Password}
						{type: \password, place: 'Ulangi password'}
					]map (i) -> m \.field, m \.control, m \input.input,
						type: i.type, placeholder: i.place
					m \.field, m \.control, m \input.button,
						type: \submit, value: \Daftarkan
				[til 2]map -> m \br
				m \h5, 'Daftar Pengguna Sistem'
				m \table.table,
					oncreate: -> Meteor.subscribe \users, onReady: -> m.redraw!
					m \thead, m \tr, <[ Username Peran Aksi ]>map (i) -> m \th, i
					m \tbody, pagins(Meteor.users.find!fetch!reverse!)map (i) -> m \tr,
						ondblclick: -> state.modal = i
						m \td, i.username
						m \td, JSON.stringify i.roles
						m \td, m \.button.is-danger,
							onclick: -> Meteor.call \rmRole, i._id
							m \span, \Reset
					if state.modal then elem.modal do
						title: 'Berikan Peranan'
						content: m autoForm do
							schema: new SimpleSchema schema.addRole
							type: \method
							meteormethod: \addRole
							id: \formAddRole
							buttonContent: \Beri
							columns: 3
							hooks:
								before: (doc, cb) ->
									cb _.merge doc, id: state.modal._id
								after: ->
									state.modal = null
									m.redraw!
				elem.pagins!
			else if \imports is m.route.param \subroute then m \.content,
				m \h1, 'Importer Data'
				m \h5, 'Unggah data csv'
				m \.file, m \label.file-label,
					m \input.file-input, type: \file, name: \csv, onchange: (e) ->
						Papa.parse e.target.files.0, header: true, step: (result) ->
							data = result.data.0
							if data.no_mr
								sel = no_mr: +data.no_mr
								opt = regis:
									nama_lengkap: _.startCase data.nama_lengkap
									alamat: _.startCase that if data.alamat
									agama: +that if data.agama
									ayah: _.startCase that if data.ayah
									nikah: +that if data.nikah
									pekerjaan: +that if data.pekerjaan
									pendidikan: +that if data.pendidikan
									tgl_lahir: new Date that if Date.parse that if data.tgl_lahir
									tmpt_lahir: _.startCase that if data.tmpt_lahir
								Meteor.call \import, \pasien, sel, opt
							if data.digudang
								sel = nama: data.nama
								opt =
									jenis: +data.jenis
									satuan: +data.satuan
									nobatch: that if data.nobatch
									merek: that if data.merek
									masuk: new Date that if data.masuk
									kadaluarsa: new Date that if data.kadaluarsa
									digudang: +data.digudang
									diapotik: +that if data.diapotik
									diretur: +that if data.diretur
									beli: +that if data.beli
									jual: +that if data.jual
									suplier: that if data.suplier
									returnable: !!that if data.returnable
									anggaran: +that if data.anggaran
									pengadaan: that if data.pengadaan
									no_spk: that if data.no_spk
									tanggal_spk: new Date that if data.tanggal_spk
								Meteor.call \import, \gudang, sel, opt
							if data.harga
								sel = nama: _.snakeCase data.nama
								opt =
									harga: +data.harga
									jenis: _.snakeCase data.jenis
									grup: _.startCase that if data.grup
									active: true
								Meteor.call \import, \tarif, sel, opt
							if data.password
								<[ newUser importRoles ]>map (i) ->
									Meteor.call i, data
					m \span.file-cta,
						m \span.file-icon, m \i.fa.fa-upload
						m \span.file-label, 'Pilih file .csv'
				[til 2]map -> m \br
				m \h5, 'Daftar Tarif Tindakan'
				m \table.table,
					oncreate: ->
						Meteor.subscribe \coll, \tarif, onReady: -> m.redraw!
						coll.tarif.find!observe added: -> m.redraw!
					m \thead, m \tr, attr.manajemen.headers.tarif.map (i) ->
						m \th, _.startCase i
					m \tbody, pagins(coll.tarif.find!fetch!)map (i) -> m \tr,
						attr.manajemen.headers.tarif.map (j) -> m \td, _.startCase i[j]
				elem.pagins!
		amprah: -> view: -> m \.content,
			oncreate: -> Meteor.subscribe \coll, \gudang, {jenis: 4}, onReady: -> m.redraw!
			m \h5, 'Form Amprah'
			unless userGroup! is \farmasi then m autoForm do
				collection: coll.amprah
				schema: new SimpleSchema schema.amprah
				type: \insert
				id: \formAmprah
			m \br
			m \h5, 'Daftar Amprah'
			m \table.table,
				oncreate: ->
					cond = ->
						if userGroup! is \obat then penyerah: $exists: false
						else if userGroup is \farmasi then ruangan: \apotik
						else ruangan: userGroup!
					Meteor.subscribe \coll, \amprah, cond!, onReady: -> m.redraw!
				m \thead, m \tr,
					attr.amprah.headers.requests.map (i) -> m \th, _.startCase i
					if userGroup! is \obat then m \th, \Serah
				m \tbody, coll.amprah.find!fetch!map (i) -> m \tr, tds arr =
					_.startCase i.ruangan
					_.startCase (.username) Meteor.users.findOne i.peminta
					"#{i.jumlah} unit"
					look2(\gudang, i.nama)nama
					if i.penyerah
						_.startCase (.username) Meteor.users.findOne that
					if i.diserah then "#that unit"
					if not i.diserah and userGroup! in <[ obat farmasi ]>
						m \.button.is-primary,
							onclick: -> state.modal = i
							m \span, \Serah
			if state.modal then elem.modal do
				title: 'Respon Amprah'
				content: m autoForm do
					schema: new SimpleSchema schema.responAmprah
					id: \formResponAmprah
					type: \method
					meteormethod: \serahAmprah
					hooks:
						before: (doc, cb) -> cb _.merge doc, that
						after: -> console.log \sudah

	m.route.prefix ''
	m.route document.body, \/dashboard,
		_.merge '/dashboard': comp.layout(comp.welcome!),
			... modules.map ({name}) -> "/#name": comp.layout comp[name]?!
			'/regis/:jenis': comp.layout comp.pasien!
			'/regis/:jenis/:idpasien': comp.layout comp.pasien!
			'/jalan/:idpasien': comp.layout comp.pasien!
			'/manajemen/:subroute': comp.layout comp.manajemen!
			'/login': comp.layout comp.login!
			'/farmasi/:idbarang': comp.layout comp.farmasi!
