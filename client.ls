if Meteor.isClient

	@state = pagins: limit: 5, page: 0
	attr =
		pasien:
			showForm:
				patient: onclick: ->
					state.showAddPatient = not state.showAddPatient
				rawat: onclick: ->
					state.showAddRawat = not state.showAddRawat
			headers:
				patientList: <[ nama_lengkap tanggal_lahir tempat_lahir ]>
				rawatFields: <[ tanggal klinik cara_bayar bayar_pendaftaran status_bayar cek ]>
		manajemen:
			headers:
				tarif: <[ nama jenis harga grup active ]>

	layout = (comp) ->
		view: -> m \div,
			m \link, rel: \stylesheet, href: 'https:/maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css'
			m \nav.navbar.is-info,
				role: \navigation, 'aria-label': 'main navigation',
				m \.navbar-brand, m \a.navbar-item, href: \#, \RSPB
			m \.columns,
				m \.column.is-2, m \aside.menu.box,
					m \p.menu-label, 'Admin Menu'
					m \ul.menu-list, modules.map (i) ->
						m \li, m "a##{i.name}",
							href: "/#{i.name}"
							class: \is-active if state.activeMenu is i.name
							m \span, _.startCase i.full
							if currentRoute! is \manajemen
								if i.name is \manajemen
									m \ul, <[ users imports ]>map (i) ->
										m \li, m \a,
											href: "/manajemen/#i"
											m \span, _.startCase i
				m \.column, if comp then m that

	comp =
		welcome: -> view: -> m \.content,
			m \h1, \Panduan
			m \p, 'Selamat datang di SIMRSPB 2018'
		pasien: -> view: -> m \div,
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
					oncreate: -> Meteor.subscribe \coll, \pasien,
						onReady: -> m.redraw!
					m \thead, m \tr, attr.pasien.headers.patientList.map (i) ->
						m \th, _.startCase i
					m \tfoot, coll.pasien.find!fetch!map (i) -> m \tr,
						ondblclick: -> m.route.set "#{m.route.get!}/#{i._id}"
						if i.regis.nama_lengkap then m \td, _.startCase that
						if i.regis.tgl_lahir then m \td, moment(that)format 'D MMM YYYY'
						if i.regis.tmpt_lahir then m \td, _.startCase that
			else m \div,
				oncreate: -> Meteor.subscribe \coll, \pasien,
					{_id: m.route.param \idpasien}, onReady: -> m.redraw!
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
						m \.button.is-success, attr.pasien.showForm.rawat, \+Pasien
					state.showAddRawat and m autoForm do
						collection: coll.pasien
						schema: new SimpleSchema schema.jalan
						type: \update-pushArray
						id: \formJalan
						scope: \rawat
						doc: that
						buttonContent: \Tambahkan
					m \table.table,
						m \thead, m \tr, attr.pasien.headers.rawatFields.map (i) ->
							m \th, _.startCase i
						m \tbody, _.reverse that.rawat.map (i) -> m \tr,
							m \td, hari i.tanggal
							m \td, look(\klinik, i.klinik)label
							m \td, look(\cara_bayar, i.cara_bayar)label
							m \td, \-
							m \td, \-
							m \td, m \button.button.is-info,
								onclick: -> state.modal = i
								m \span, \Cek
					if state.modal then elem.modal do
						title: 'Rincian rawat'
						confirm: \Lanjutkan
						content: m \div,
							m \h1, coll.pasien.findOne!regis.nama_lengkap
							m \table.table, [
								{head: \Tanggal, cell: hari state.modal.tanggal}
								{head: \Klinik, cell: look(\klinik, state.modal.klinik)label}
								{head: 'Cara Bayar', cell: look(\cara_bayar, state.modal.cara_bayar)label}
								{head: 'Anamesa Perawat', cell: state.modal?anamesa_perawat}
								{head: 'Anamesa Dokter', cell: state.modal?anamesa_dokter}
								{head: \Diagnosa, cell: state.modal?diagnosa}
								{head: \Planning, cell: state.modal?planning}
							]map (i) -> m \tr, [(m \th, i.head), (m \td, i.cell)]
		regis: -> this.pasien
		jalan: -> this.pasien
		manajemen: -> view: ->
			if \users is m.route.param \subroute then m \.content,
				oncreate: -> Meteor.subscribe \users, onReady: -> m.redraw!
				m \h1, 'Manajemen Pengguna'
				m \h5, 'Tambahkan pengguna baru'
				m \form,
					onsubmit: (e) ->
						e.preventDefault!
						vals = _.initial _.map e.target, -> it.value
						if vals.1 is vals.2
							Meteor.call \newUser, username: vals.0, password: vals.1
					[
						{type: \text, place: \Username}
						{type: \password, place: \Password}
						{type: \password, place: 'Ulangi password'}
					]map (i) -> m \.field, m \.control, m \input.input,
						type: i.type, placeholder: i.place
					m \.field, m \.control, m \input.button,
						type: \submit, value: \Daftarkan
				m \table.table,
					m \thead, m \tr, <[ username peranan ]>map (i) -> m \th, _.startCase i
					m \tbody, Meteor.users.find!fetch!map (i) -> m \tr,
						ondblclick: -> state.modal = i
						m \td, i.username
						m \td, ''
					if state.modal then elem.modal do
						title: 'Berikan peranan'
						confirm: \Beri
						content: m \.content, m \p, \coba
			else if \imports is m.route.param \subroute then m \.content,
				m \h1, 'Importer Data'
				m \h5, 'Unggah data csv'
				m \.file, m \label.file-label,
					m \input.file-input,
						type: \file, name: \csv,
						onchange: (e) -> Papa.parse e.target.files.0,
							header: true, step: (result) ->
								data = result.data.0
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
					m \span.file-cta,
						m \span.file-icon, m \i.fa.fa-upload
						m \span.file-label, 'Pilih file .csv'
				[til 2]map -> m \br
				m \h5, 'Daftar Tarif Tindakan'
				m \table.table,
					oncreate: -> Meteor.subscribe \coll, \tarif, onReady: -> m.redraw!
					m \thead, m \tr, attr.manajemen.headers.tarif.map (i) ->
						m \th, _.startCase i
					m \tbody, pagins(coll.tarif.find!fetch!)map (i) -> m \tr,
						attr.manajemen.headers.tarif.map (j) -> m \td, _.startCase i[j]
				elem.pagins coll.tarif.find!fetch!

	m.route.prefix ''
	m.route document.body, \/dashboard,
		_.merge '/dashboard': layout(comp.welcome!),
			... modules.map ({name}) -> "/#name": layout comp[name]?!
			'/regis/:idpasien': layout comp.pasien!
			'/jalan/:idpasien': layout comp.pasien!
			'/manajemen/:subroute': layout comp.manajemen!
