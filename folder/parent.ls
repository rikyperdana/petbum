@look = (list, val) -> selects[list]find -> it.value is val
@look2 = (list, id) -> coll[list]find!fetch!find -> it._id is id
@randomId = -> Math.random!toString 36 .slice 2
@zeros = -> \0 * (6 - it.toString!length) + it
@min = -> reduce it, (res, inc) -> if inc < res then inc else res
@max = -> reduce it, (res, inc) -> if inc > res then inc else res
@abs = -> Math.sqrt Math.pow it, 2
@dayDiff = (date) ->
	diff = date.getTime! - (new Date!)getTime!
	diff /= 1000ms * 60sec * 60min * 24hour
	Math.round diff
@hari = -> moment it .format 'D MMM YYYY'
@rupiah = -> "Rp #{numeral(+it or 0)format '0,000.00'},-"
@ols = -> m \ol, it.map -> m \li, it
@hmac = require \crypto-js/hmac-sha256

if Meteor.isClient

	@state = notify: {}, pagins: limit: 10, page: 0
	@currentRoute = -> m.route.get!split \/ .1
	@isDr = -> _.split Meteor.user!?username, \. .0 in <[ dr drg ]>
	@roles = -> Meteor.user!?roles
	@tds = -> it.map (i) -> m \td, i
	@userRole = ->
		if it then roles!?[currentRoute!]?0 is that
		else (?0?0) _.values roles!
	@userGroup = ->
		if it then roles!?[that]
		else (?0) _.keys roles!
	@pagins = ->
		position = state.pagins.page * state.pagins.limit
		_.slice it, position, (position + state.pagins.limit)
	@elem =
		modal: (obj) -> m \.modal.is-active,
			m \.modal-background
			m \.modal-card,
				m \header.modal-card-head,
					m \p.modal-card-title, obj.title
					unless obj.noClose then m \button.delete,
						'aria-label': \close onclick: -> state.modal = null
				if obj.content then m \section.modal-card-body, m \.content, that
				m \footer.modal-card-foot,
					if obj.confirm then m \button.button.is-success,
						(onclick: -> obj.action?!), m \span, that
					if obj.danger then m \button.button.is-danger,
						(onclick: -> obj.dangerAction?!), that
		pagins: (arr) -> m \nav.pagination, role: \navigation, 'aria-label': \pagination,
			[[\previous, -1], [\next, 1]]map (i) -> m ".pagination-#{i.0}",
				onclick: -> state.pagins.page += i.1
				m \span, _.startCase i.0
			m \.pagination-list, [til 3]map (i) -> m \a.pagination-link,
				m \span, _.startCase state.pagins.page+i+1
		report: ({title, action, fields}) ->
			m \.box, (m \h5, title), m autoForm do ->
				schema =
					start: type: Date, label: \Mulai
					end: type: Date, label: \Akhir
					type: type: String, autoform: options:
						<[Pdf Excel]>map -> label: it, value: it
				if fields then _.assign schema, options: that
				schema: new SimpleSchema schema
				id: \formReport
				columns: 3
				type: \method
				meteormethod: \dummy
				hooks: after: action
	@csv = (title, docs) ->
		content = exportcsv.exportToCSV docs, true, \;
		blob = new Blob [content], type: 'text/plain;charset=utf-8'
		saveAs blob, "#title.csv"
