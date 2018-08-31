@look = (list, val) -> selects[list]find -> it.value is val
@look2 = (list, id) -> coll[list]find!fetch!find -> it._id is id
@randomId = -> Math.random!toString 36 .slice 2
@zeros = -> \0 * (6 - it.toString!length) + it
@monthDiff = (date) ->
	diff = date.getTime! - (new Date!)getTime!
	diff /= 1000ms * 60sec * 60min * 24hour * 7day * 4week
	Math.round diff

if Meteor.isClient

	@state = pagins: limit: 5, page: 0
	@hari = -> moment it .format 'D MMM YYYY'
	@currentRoute = -> m.route.get!split(\/).1
	@pagins = ->
		position = state.pagins.page * state.pagins.limit
		_.slice it, position, (position + state.pagins.limit)
	@elem =
		modal: ({title, content, confirm, action}) -> m \.modal.is-active,
			m \.modal-background
			m \.modal-card,
				m \header.modal-card-head,
					m \p.modal-card-title, title
					m \button.delete, 'aria-label': \close onclick: -> state.modal = null
				m \section.modal-card-body, m \.content, content
				m \footer.modal-card-foot, m \button.button.is-success,
					(onclick: -> action?!), m \span, confirm
		pagins: (arr) -> m \nav.pagination, role: \navigation, 'aria-label': \pagination,
			[[\previous, -1], [\next, 1]]map (i) -> m ".pagination-#{i.0}",
				onclick: -> state.pagins.page += i.1
				m \span, _.startCase i.0
			m \.pagination-list, [til 3]map (i) -> m \a.pagination-link,
				m \span, _.startCase state.pagins.page+i+1
