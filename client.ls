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
				patientList: <[ nama_lengkap tanggal_lahir tempat_lahir ]>
				rawatFields: <[ tanggal klinik cara_bayar bayar_pendaftaran status_bayar cek ]>
			rawatDetails: (doc) -> arr =
				{head: \Tanggal, cell: hari doc.tanggal}
				{head: \Klinik, cell: look(\klinik, doc.klinik)label}
				{head: 'Cara Bayar', cell: look(\cara_bayar, doc.cara_bayar)label}
				{head: 'Anamesa Perawat', cell: doc?anamesa_perawat}
				{head: 'Anamesa Dokter', cell: doc?anamesa_dokter}
				{head: \Diagnosa, cell: doc?diagnosa}
				{head: \Planning, cell: doc?planning}
		bayar: header: <[ no_mr nama tanggal total_biaya cara_bayar klinik aksi ]>
		manajemen:
			headers:
				tarif: <[ nama jenis harga grup active ]>

	comp =
		layout: (comp) ->
			view: -> m \div,
				unless Meteor.userId! then m.route.set \/login
				m \link, rel: \stylesheet, href: 'https:/maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css'
				m \nav.navbar.is-info,
					role: \navigation, 'aria-label': 'main navigation',
					m \.navbar-brand, m \a.navbar-item, href: \#, \RSPB
				m \.columns,
					Meteor.userId! and m \.column.is-2, m \aside.menu.box,
						m \p.menu-label, 'Admin Menu'
						m \ul.menu-list, attr.layout.rights!map (i) ->
							m \li, m "a##{i.name}",
								href: "/#{i.name}"
								class: \is-active if state.activeMenu is i.name
								m \span, _.startCase i.full
								if same \manajemen, currentRoute!, i.name
									m \ul, <[ users imports ]>map (i) ->
										m \li, m \a,
											href: "/manajemen/#i"
											m \span, _.startCase i
					m \.column, if comp then m that
		login: -> view: -> m \.container,
			m \.content, m \h5, \Login
			m \form,
				onsubmit: (e) ->
					e.preventDefault!
					vals = _.initial _.map e.target, -> it.value
					Meteor.loginWithPassword ...vals, (err) ->
						unless err then m.route.set \/dashboard
				m \input.input, type: \text, placeholder: \Username
				m \input.input, type: \password, placeholder: \Password
				m \input.button.is-success, type: \submit, value: \Login
		welcome: -> view: -> m \.content,
			m \h1, \Panduan
			m \p, 'Selamat datang di SIMRSPB 2018'
		pasien: -> view: -> m \.content,
			if currentRoute! is \regis then unless m.route.param \idpasien
				m \.button.is-success, attr.pasien.showForm.patient, \+Pasien
			state.showAddPatient and  m autoForm do
				collection: coll.pasien
				schema: new SimpleSchema schema.regis
				type: \insert
				id: \formRegis
				buttonContent: \Simpan
			unless m.route.param \idpasien
				m \table.table,
					oncreate: ->
						Meteor.subscribe \coll, \pasien, onReady: -> m.redraw!
					m \thead, m \tr, attr.pasien.headers.patientList.map (i) ->
						m \th, _.startCase i
					m \tfoot, coll.pasien.find!fetch!map (i) ->
						rows = -> m \tr,
							ondblclick: -> m.route.set "#{m.route.get!}/#{i._id}"
							m \td, if i.regis.nama_lengkap then _.startCase that
							m \td, if i.regis.tgl_lahir then moment(that)format 'D MMM YYYY'
							m \td, if i.regis.tmpt_lahir then _.startCase that
						if currentRoute! is \jalan
							if i.rawat?reverse!?0?billRegis then rows!
						else rows!
			else m \div,
				oncreate: ->
					Meteor.subscribe \coll, \pasien,
						{_id: m.route.param \idpasien}, onReady: -> m.redraw!
					Meteor.subscribe \coll, \tarif
				m \.content, m \h5, 'Rincian Pasien'
				if coll.pasien.findOne(_id: m.route.param \idpasien) then m \div,
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
					if currentRoute! is \regis
						m \.button.is-success, attr.pasien.showForm.rawat, \+Rawat
					state.showAddRawat and m autoForm do
						collection: coll.pasien
						schema: new SimpleSchema schema.rawatRegis
						type: \update-pushArray
						id: \formJalan
						scope: \rawat
						doc: that
						buttonContent: \Tambahkan
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
						hooks: before: (doc, cb) ->
							Meteor.call \rmRawat, that._id, state.docRawat, (err, res) ->
								res and cb _.merge doc.rawat.0, that.rawat.find ->
									it.idrawat is state.docRawat
					m \table.table,
						m \thead, m \tr, attr.pasien.headers.rawatFields.map (i) ->
							m \th, _.startCase i
						m \tbody, that.rawat?reverse!map (i) -> m \tr, [
							hari i.tanggal
							look(\klinik, i.klinik)label
							look(\cara_bayar, i.cara_bayar)label
							... [til 2]map -> \-
							m \button.button.is-info,
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
							state.modal = null
		regis: -> this.pasien
		jalan: -> this.pasien
		bayar: -> view: -> m \.content,
			m \table.table,
				oncreate: ->
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
						(hari j.tanggal), \-
						look(\cara_bayar, j.cara_bayar)label
						look(\klinik, j.klinik)label
						m \a.button.is-success,
							onclick: -> state.modal = _.merge j, pasienId: i._id
							m \span, \Bayar
					]map (k) -> m \td, k
			if state.modal then elem.modal do
				title: 'Sudah bayar?'
				content: m \table.table,
					m \tr, [(m \th, 'Total Biaya'), (m \td, "Rp #{state.modal.karcis}")]
				confirm: \Sudah
				action: ->
					if state.modal then Meteor.call \updateArrayElm,
						name: \pasien, recId: that.pasienId,
						scope: \rawat, elmId: that.idrawat, doc: _.merge that,
							if !that.billRegis then billRegis: true
							else if !that.status_bayar then status_bayar: true
					state.modal = null
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
					m \input.file-input,
						type: \file, name: \csv,
						onchange: (e) -> Papa.parse e.target.files.0,
							header: true, step: (result) ->
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
									<[ newUser addRoles ]>map (i) ->
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
			'/regis/:idpasien': comp.layout comp.pasien!
			'/jalan/:idpasien': comp.layout comp.pasien!
			'/manajemen/:subroute': comp.layout comp.manajemen!
			'/login': comp.layout comp.login!
