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
			m \table.table,
				oncreate: -> Meteor.subscribe \coll, \pasien,
					onReady: -> m.redraw!
				m \thead, m \tr, attr.regis.table.headers.map (i) ->
					m \th, _.startCase i
				m \tfoot, coll.pasien.find!fetch!map (i) -> m \tr,
					onclick: -> m.route.set "/regis/#{i._id}"
					if i.regis.nama_lengkap then m \td, _.startCase that
					if i.regis.tgl_lahir then m \td, that.toString!
					if i.regis.tmpt_lahir then m \td, _.startCase that

	m.route.prefix ''
	m.route document.body, \/dashboard,
		_.merge '/dashboard': layout(comp.welcome!),
			... modules.map ({name}) -> "/#name": layout comp[name]?!
			'/regis/:idpasien': layout comp.regis!
