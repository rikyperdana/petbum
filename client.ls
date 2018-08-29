if Meteor.isClient

	@state = {}
	attr =
		menuLink: (name) ->
			onclick: ->
				state.activeMenu = name
			class: \is-active if state.activeMenu is name
			href: "/#name"
			oncreate: m.route.link
		pasien:
			showForm:
				patient: onclick: ->
					state.showAddPatient = not state.showAddPatient
				rawat: onclick: ->
					state.showAddRawat = not state.showAddRawat
			headers:
				patientList: <[ nama_lengkap tanggal_lahir tempat_lahir ]>
				rawatFields: <[ tanggal klinik cara_bayar bayar_pendaftaran status_bayar cek ]>

	layout = (comp) ->
		view: -> m \div,
			m \nav.navbar.is-info,
				role: \navigation, 'aria-label': 'main navigation',
				m \.navbar-brand, m \a.navbar-item, href: \#, \RSPB
			m \.columns,
				m \.column.is-2, m \aside.menu.box,
					m \p.menu-label, 'Admin Menu'
					m \ul.menu-list, modules.map (i) ->
						m \li, m "a##{i.name}",
							attr.menuLink(i.name), _.startCase i.full
				m \.column, if comp then m that

	comp =
		welcome: -> view: -> m \.content,
			m \h1, \Panduan
			m \p, 'Selamat datang di SIMRSPB 2018'
		modal: ({title, content, confirm, cancel}) -> m \.modal,
			class: \is-active
			m \.modal-background
			m \.modal-card,
				m \header.modal-card-head,
					m \p.modal-card-title, title
					m \button.delete,
						'aria-label': \close
						onclick: -> state.modal = null
				m \section.modal-card-body, m \.content, content
				m \footer.modal-card-foot,
					m \button.button.is-success, confirm
					m \button.button, cancel
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
					if state.modal then comp.modal do
						title: 'Rincian rawat'
						confirm: \Lanjutkan
						cancel: \Batal
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
		manajemen: -> view: -> m \.content,
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
				if state.modal then comp.modal do
					title: 'Berikan peranan'
					confirm: \Beri
					cancel: \Batal
					content: m \.content, m \p, \coba
	m.route.prefix ''
	m.route document.body, \/dashboard,
		_.merge '/dashboard': layout(comp.welcome!),
			... modules.map ({name}) -> "/#name": layout comp[name]?!
			'/regis/:idpasien': layout comp.pasien!
			'/jalan/:idpasien': layout comp.pasien!
