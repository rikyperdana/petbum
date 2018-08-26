if Meteor.isClient

	@state = {}

	attr =
		menuLink: (name) ->
			onclick: ->
				state.activeMenu = name
			class: \is-active if state.activeMenu is name
			href: "/#name"
			oncreate: m.route.link
		regis:
			button: onclick: ->
				state.showForm = not state.showForm
			table: headers: <[ nama_lengkap tanggal_lahir tempat_lahir ]>

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
		regis: -> view: -> m \div,
			m \.button.is-success, attr.regis.button, \+Pasien
			state.showForm and  m autoForm do
				collection: coll.pasien
				schema: schema.regis
				type: \insert
				id: \formRegis
				buttonContent: \Simpan
			unless m.route.param \idpasien
				m \table.table,
					oncreate: -> Meteor.subscribe \coll, \pasien,
						onReady: -> m.redraw!
					m \thead, m \tr, attr.regis.table.headers.map (i) ->
						m \th, _.startCase i
					m \tfoot, coll.pasien.find!fetch!map (i) -> m \tr,
						ondblclick: -> m.route.set "/regis/#{i._id}"
						if i.regis.nama_lengkap then m \td, _.startCase that
						if i.regis.tgl_lahir then m \td, moment(that)format 'D MMM YYYY'
						if i.regis.tmpt_lahir then m \td, _.startCase that
			else m \div,
				oncreate: -> Meteor.subscribe \coll, \pasien,
					{_id: m.route.param \idpasien}, onReady: -> m.redraw!
				m \.content, m \h5, 'Rincian Pasien'
				if coll.pasien.findOne(_id: m.route.param \idpasien)
					m \table.table, [
						[
							{name: 'No. MR', data: that.no_mr}
							{name: 'Tanggal Lahir', data: that.regis.tgl_lahir.toString!}
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

	m.route.prefix ''
	m.route document.body, \/dashboard,
		_.merge '/dashboard': layout(comp.welcome!),
			... modules.map ({name}) -> "/#name": layout comp[name]?!
			'/regis/:idpasien': layout comp.regis!
