if Meteor.isClient

	attr =
		layout:
			rights: -> modules.filter (i) ->
				i.name in _.flatMap (_.keys Meteor.user!?roles), (j) ->
					(.list) rights.find -> it.group is j
		pasien:
			showForm:
				patient: onclick: ->
					state.showAddPatient = not state.showAddPatient
				rawat: onclick: ->
					state.showAddRawat = not state.showAddRawat
			headers:
				patientList: <[ nama_lengkap tanggal_lahir tempat_lahir poliklinik ]>
				rawatFields: <[ tanggal klinik cara_bayar bayar_pendaftaran status_bayar cek ]>
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
		bayar: header: <[ no_mr nama tanggal cara_bayar klinik aksi ]>
		apotik:
			header: <[ no_mr nama tanggal total_biaya cara_bayar klinik aksi ]>
		gudang: headers:
			farmasi: <[ jenis_barang nama_barang stok_gudang stok_diapotik hapus ]>
			rincian: <[ nobatch digudang diapotik masuk kadaluarsa ]>
		farmasi: fieldSerah: <[ nama_obat jumlah_obat aturan_kali aturan_dosis ]>
		manajemen: headers: tarif: <[ nama jenis harga grup active ]>

	comp =
		layout: (comp) ->
			view: -> m \div,
				unless Meteor.userId! then m.route.set \/login
				m \link, rel: \stylesheet, href: 'https:/maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css'
				m \nav.navbar.is-info,
					role: \navigation, 'aria-label': 'main navigation',
					m \.navbar-brand, m \a.navbar-item, href: \#, \RSPB
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
								if \regis is currentRoute!
									m \ul, <[ baru lama ]>map (i) -> m \li, m \a,
										href: "/regis/#i", oncreate: m.route.link, "Pasien #i"
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
			if \baru is m.route.param \jenis then m autoForm do
				collection: coll.pasien
				schema: new SimpleSchema schema.regis
				type: \insert
				id: \formRegis
				buttonContent: \Simpan
				hooks: after: -> state.showAddPatient = null
			unless m.route.param \idpasien then m \div,
				m \form,
					onsubmit: (e) ->
						e.preventDefault!
						Meteor.subscribe \coll, \pasien,
							{'regis.nama_lengkap': $options: \-i, $regex: ".*#{e.target.0.value}.*"}
							onReady: -> m.redraw!
					m \input.input, type: \text, placeholder: \Pencarian
				m \table.table,
					m \thead, m \tr, attr.pasien.headers.patientList.map (i) ->
						m \th, _.startCase i
					m \tfoot, coll.pasien.find!fetch!map (i) ->
						rows = -> m \tr,
							ondblclick: -> m.route.set "#{m.route.get!}/#{i._id}"
							m \td, if i.regis.nama_lengkap then _.startCase that
							m \td, if i.regis.tgl_lahir then moment(that)format 'D MMM YYYY'
							m \td, if i.regis.tmpt_lahir then _.startCase that
							m \td, _.startCase userRole!
						if currentRoute! is \jalan
							if i.rawat?reverse!?0?billRegis then rows!
						else rows!
			else m \div,
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
						m \.button.is-success, attr.pasien.showForm.rawat, \+Rawat
					state.showAddRawat and m autoForm do
						collection: coll.pasien
						schema: new SimpleSchema schema.rawatRegis
						type: \update-pushArray
						id: \formJalan
						scope: \rawat
						doc: that
						buttonContent: \Tambahkan
						hooks: after: -> state.showAddRawat = false
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
						hooks:
							before: (doc, cb) ->
								Meteor.call \rmRawat, that._id, state.docRawat, (err, res) ->
									res and cb _.merge doc.rawat.0, that.rawat.find ->
										it.idrawat is state.docRawat
							after: -> console.log \sudah
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
						confirm: \Lanjutkan if ands arr =
							currentRoute! is \jalan
							if !isDr! then !state.modal.anamesa_perawat else true
							if isDr! then state.modal.anamesa_perawat else true
							if isDr! then !state.modal.anamesa_dokter else true
						action: ->
							state.docRawat = state.modal.idrawat
							state.spm = new Date!
							state.modal = null
		regis: -> this.pasien
		jalan: -> this.pasien
		bayar: -> view: -> m \.content,
			m \table.table,
				oncreate: ->
					Meteor.subscribe \coll, \tarif
					Meteor.subscribe \coll, \pasien,
						$elemMatch: $or: arr =
							billRegis: $ne: true
							status_bayar: $ne: true
						onReady: -> m.redraw!
					coll.pasien.find!observe changed: -> m.redraw!
				m \thead, m \tr, attr.bayar.header.map (i) -> m \th, _.startCase i
				m \tbody, coll.pasien.find!fetch!map (i) -> _.compact i.rawat.map (j) ->
					if !j.billRegis or (if j.tindakan then !j.status_bayar) then m \tr, [
						i.no_mr, i.regis.nama_lengkap,
						hari j.tanggal
						look(\cara_bayar, j.cara_bayar)label
						look(\klinik, j.klinik)label
						m \a.button.is-success,
							onclick: -> state.modal = _.merge j, pasienId: i._id
							m \span, \Bayar
					]map (k) -> m \td, k
			if state.modal then elem.modal do
				title: 'Sudah bayar?'
				content: do ->
					tindakans = state.modal.tindakan?map -> arr =
						_.startCase look2(\tarif, it.nama)nama
						it.harga
					arr =
						['Daftar Baru', 10000] unless coll.pasien.findOne(state.modal.pasienId)rawat?1
						['Daftar Rawat', 30000] unless state.modal.billRegis
						... tindakans or []
					if arr then m \table.table,
						that.map (i) -> if i then m \tr, [(m \th, i.0), (m \td, rupiah i.1)]
						m \tr, [(m \th, 'Total Biaya'), (m \td, rupiah _.sum arr.map -> it.1)]
				confirm: \Sudah
				action: ->
					Meteor.call \updateArrayElm,
						name: \pasien, recId: that.pasienId,
						scope: \rawat, elmId: that.idrawat, doc: _.merge that,
							if !that.billRegis then billRegis: true
							else if !that.status_bayar then status_bayar: true
					state.modal = null
		obat: -> view: -> m \.content,
			m \h5, \Apotik,
			m \table.table,
				oncreate: ->
					Meteor.subscribe \coll, \rekap, printed: $exists: false
					Meteor.subscribe \coll, \pasien,
						{rawat: $elemMatch: obat: $elemMatch: hasil: $exists: false}
						onReady: -> m.redraw!
				m \thead, attr.apotik.header.map (i) -> m \th, _.startCase i
				m \tbody, coll.pasien.find!fetch!map (i) -> i.rawat.map (j) ->
					j.obat?map (k) -> unless k.hasil then m \tr,
						m \td, i.no_mr
						m \td, i.regis.nama_lengkap
						m \td, hari j.tanggal
						m \td, \-
						m \td, look(\cara_bayar, j.cara_bayar)label
						m \td, look(\klinik, j.klinik)label
						m \td, m \.button.is-success,
							onclick: -> state.modal = _.merge k, j, i
							m \span, \Serah
			if state.modal then elem.modal do
				title: 'Serahkan Obat?'
				content: m \table.table,
					oncreate: -> Meteor.subscribe \coll, \gudang,
						onReady: -> m.redraw!
					m \tr, attr.farmasi.fieldSerah.map (i) ->
						m \th, _.startCase i
					m \tr,
						m \td, look2(\gudang, state.modal.nama)?nama
						m \td, "#{state.modal.jumlah} unit"
						m \td, "#{state.modal.aturan.kali} kali sehari"
						m \td, "#{state.modal.aturan.dosis} unit per konsumsi"
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
			m \.button.is-warning,
				onclick: -> makePdf.rekap!
				m \span, 'Cetak Rekap'
		farmasi: -> view: -> m \.content,
			unless m.route.param(\idbarang) then m \div,
				m \button.button.is-success,
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
						hooks: after: -> state.showForm = null
				m \table.table,
					oncreate: -> Meteor.subscribe \coll, \gudang, onReady: -> m.redraw!
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
				m \.button.is-warning,
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
					hooks: after: ->
						Meteor.call \sortByDate, m.route.param \idbarang
						state.showForm = null
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
							hooks:
								before: (doc, cb) ->
									cb _.merge doc, id: state.modal._id
								after: -> state.modal = null
				elem.pagins!
			else if \imports is m.route.param \subroute then m \.content,
				m \h1, 'Importer Data'
				m \h5, 'Unggah data csv'
				m \.file, m \label.file-label,
					m \input.file-input, type: \file, name: \csv, onchange: (e) ->
						Papa.parse e.target.files.0, header: true, step: (result) ->
							data = result.data.0
							if data.no_mr
								sel = no_mr: data.no_mr
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
