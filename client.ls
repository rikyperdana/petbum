if Meteor.isClient

	state = {}

	layout = (comp) ->
		attr =
			menuLink: (name) ->
				onclick: ->
					state.activeMenu = name
				class: \is-active if state.activeMenu is name
				href: "/#name"
				oncreate: m.route.link
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
				m \.column, if comp then that

	attr =
		regis:
			button: onclick: ->
				state.showForm = true

	comp =
		welcome: -> m \.content,
			m \h1, \Panduan
			m \p, 'Selamat datang di SIMRSPB 2018'
		regis: -> m \div,
			m \.button.is-success, attr.regis.button, \+Pasien
			state.showForm and  m autoForm do
				collection: coll.pasien
				schema: schema.regis
				type: \insert
				id: \formRegis
				buttonContent: \Simpan

	m.route.prefix ''
	m.route document.body, \/dashboard,
		_.merge '/dashboard': layout(comp.welcome!),
			... modules.map ({name}) -> "/#name": layout comp.regis!
