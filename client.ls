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
					if state.modal then m \.modal,
						class: \is-active if state.modal
						m \.modal-background
						m \.modal-card,
							m \header.modal-card-head,
								m \p.modal-card-title, 'Rincian Rawat'
								m \button.delete,
									'aria-label': \close
									onclick: -> state.modal = null
							m \section.modal-card-body, m \.content,
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
							m \footer.modal-card-foot,
								m \button.button.is-success, 'Lanjutkan data'
								m \button.button, \Batal
		regis: -> this.pasien
		jalan: -> this.pasien

	m.route.prefix ''
	m.route document.body, \/dashboard,
		_.merge '/dashboard': layout(comp.welcome!),
			... modules.map ({name}) -> "/#name": layout comp[name]?!
			'/regis/:idpasien': layout comp.pasien!
			'/jalan/:idpasien': layout comp.pasien!
