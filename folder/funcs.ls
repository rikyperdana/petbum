@_ = lodash
@coll = {}; @schema = {}; @afState = {};
@ors = -> it.find -> it
@ands = -> _.last it if _.every it
@bool = -> !!it
@reduce = (...params) ->
	if params.length is 2
		(Object.values params.0)reduce params.1
	else if params.length is 3
		(Object.values params.1)reduce params.2, params.0
	else 'your arguments are invalid'
@same = -> bool reduce it, (res, inc) -> inc if res is inc
@reverse = -> reduce [], it, (res, inc) -> [inc, ...res]

if Meteor.isClient
	@m = require \mithril

	@abnormalize = (obj) ->
		recurse = (name, value) ->
			if value?getMonth then "#name": value
			else if _.isObject value then _.assign {},
				... _.map value, (val, key) ->
					recurse "#name.#key", val
			else "#name": value
		_.assign {}, ... _.map (recurse \obj, obj),
			(val, key) -> "#{key.substring 4}": val

	@normalize = (obj) ->
		recurse = (value, name) ->
			if _.isObject value
				isNum = _.size _.filter value, (val, key) -> +key
				res = "#name":
					if isNum > 0 then _.map value, recurse
					else if value.getMonth then value
					else _.merge {}, ... _.map value, recurse
				if +name then res[name] else res
			else
				if +name then value
				else "#name": value
		obj = recurse obj, \obj .obj
		for key, val of obj
			if key.split(\.)length > 1
				delete obj[key]
		obj

	@autoForm = (opts) ->
		state = afState

		scope = if opts.scope then new SimpleSchema do ->
			reducer = (res, val, key) ->
				if new RegExp("^#that")test key
					_.merge res, "#key": val
				else res
			_.reduce opts.schema._schema, reducer, {}

		usedSchema = scope or opts.schema
		theSchema = (name) -> usedSchema._schema[name]

		omitFields = if opts.omitFields then _.pull do
			_.values usedSchema._firstLevelSchemaKeys
			...opts.omitFields

		usedFields = ors arr =
			omitFields
			opts.fields
			usedSchema._firstLevelSchemaKeys

		optionList = (name) -> ors arr =
			theSchema(name)?allowedValues?map (i) ->
				value: i, label: _.startCase i
			do ->
				if _.isFunction theSchema(name)?autoform?options
					theSchema(name)?autoform?options!
				else theSchema(name)?autoform?options
			<[ true false ]>map (i) ->
				value: JSON.parse i
				label: _.startCase i

		state.arrLen ?= {}; state.form ?= {}
		state.temp ?= {}; state.errors ?= {}
		state.form[opts.id] ?= {}; state.temp[opts.id] ?= []
		stateTempGet = (field) -> if state.temp[opts.id]
			_.findLast state.temp[opts.id], -> it.name is field

		# if opts.scope then opts.doc[that] = []
		abnDoc = abnormalize that if opts.doc
		normed = -> it.replace /\d/g, \$

		attr =
			form:
				id: opts.id
				onchange: ({target}) ->
					arr = <[ radio checkbox select ]>
					unless theSchema(target.name)?autoform?type in arr
						state.form[opts.id][target.name] = target.value
					opts.autosave and $ "form##{opts.id}" .submit!

				onsubmit: (e) ->
					e.preventDefault!
					temp = state.temp[opts.id]map -> "#{it.name}": it.value
					formFields = _.filter e.target, (i) ->
						a = -> (i.value isnt \on) and i.name
						arr = <[ radio checkbox select ]>
						b = -> theSchema(i)?autoform?type in arr
						a! and not b!

					formValues = formFields.map ({name, value}) ->
						name and _.reduceRight name.split(\.),
							((res, inc) -> "#inc": res)
							if value then switch theSchema(normed name)type
								when String then value
								when Number then +value
								when Date then new Date value

					obj = normalize _.merge ... temp.concat formValues

					context = usedSchema.newContext!
					context.validate _.merge {}, obj, (opts.doc or {})
					state.errors[opts.id] = _.assign {},
						... context._invalidKeys.map -> "#{it.name}": it.type

					after = (err, res) -> opts.hooks?after res if res
					formTypes = (doc) ->
						insert: -> opts.collection.insert (doc or obj), after
						update: -> opts.collection.update do
							{_id: abnDoc._id}, {$set: (doc or obj)}, after
						method: -> Meteor.call opts.meteormethod, (doc or obj), after
						'update-pushArray': -> opts.collection.update do
							{_id: abnDoc._id}
							{$push: "#{opts.scope}": $each: _.values obj[opts.scope]}
							(err, res) -> opts.hooks?after doc if res

					if opts.hooks?before then that obj, (moded) ->
						formTypes(moded)[opts.type]!
					else formTypes![opts.type]!

			radio: (name, value) ->
				type: \radio, name: name, id: "#name#value"
				checked: value is (stateTempGet(name)?value or abnDoc?[name])
				onchange: -> state.temp[opts.id]push {name, value}

			select: (name) ->
				name: name
				value: stateTempGet(name)?value or abnDoc?[name]
				onchange: ({target}) -> state.temp[opts.id]push do
					name: name, value: target.value

			checkbox: (name, value) ->
				type: \checkbox, name: name, id: "#name#value", data: value,
				onchange: -> state.temp[opts.id]push name: name, value:
					_.map $("input:checked[name='#name']"), ->
						theVal = -> if +it then that else it
						theVal it.attributes.data.nodeValue
				checked:
					if stateTempGet(name)
						value.toString! in _.map that.value, -> it.toString!
					else if abnDoc?["#name.0"]
						value.toString! in _.compact _.map abnDoc,
							(val, key) -> val.toString! if _.includes key, name

			arrLen: (name, type) -> onclick: ->
				state.arrLen[name] ?= 0
				num = inc: 1, dec: -1
				state.arrLen[name] += num[type]

		columnize = ->
			chunk = -> reduce [], it, (res, inc) ->
				end = -> [...res, [inc]]
				if inc.type in [Object, Array] then end!
				else
					[...first, last] = res
					unless last?length < opts.columns then end!
					else
						if last.0.type in [Object, Array] then end!
						else [...first, [...last, inc]]
			recDom = (i) ->
				if _.isArray i then i.map -> recDom it
				else do ->
					type = i?autoform?type or \other
					split = _.split i.name, \.
					title = ->
						if split.length is 1 then i.head
						else "#{i.head}.#{_.last split}"
					inputTypes title!, i .[type]!
			structure = -> it.map (i) ->
				m \.columns, i.map (j) -> m \div,
					class: \column unless j.attrs?type is \hidden
					j
			structure recDom chunk it

		inputTypes = (name, schema) ->
			label =
				theSchema(name)?label
				or _.startCase _.last _.split name, \.
			error = _.startCase _.find state.errors[opts.id],
				(val, key) -> key is name

			hidden: -> m \input,
				type: \hidden, name: name, id: name,
				value: schema.autoValue? name, _.map state.form[opts.id],
					(val, key) -> value: val, name: key

			textarea: -> m \div,
				m \textarea.textarea,
					name: name, id: name,
					class: \is-danger if error
					placeholder: label
					value: state.form[opts.id][name] or abnDoc?[name]
				m \p.help.is-danger, error if error

			range: -> m \div,
				m \label.label, label
				m \input,
					type: \range, id: name, name: name,
					class: \is-danger if error
					value: state.form[opts.id][name] or abnDoc?[name]?toString!
				m \p.help.is-danger, error if error

			checkbox: -> m \div,
				m \label.label, label
				optionList(name)map (j) -> m \label.checkbox,
					m \input, attr.checkbox name, j.value
					m \span, _.startCase j.label
				m \p.help.is-danger, error if error

			select: -> m \div,
				m \label.label, label
				m \.select, m \select, attr.select(name),
					m \option, value: '', ors arr =
						theSchema(normed name)autoform?firstLabel
						'Select One'
					optionList(normed name)map (j) ->
						m \option, value: j.value, j.label
				m \p.help.is-danger, error if error

			radio: -> m \.control,
				m \label.label, label
				optionList(name)map (j) -> m \label.radio,
					m \input, attr.radio name, j.value
					m \span, _.startCase j.label

			other: ->
				defaultInputTypes =
					text: String, number: Number,
					radio: Boolean, date: Date
				defaultType = -> _.toPairs(defaultInputTypes)find ->
					it.1 is schema.type
				maped = _.map usedSchema._schema, (val, key) ->
					_.merge val, name: key

				if schema.autoform?options
					inputTypes name, defaultType!0 .select!

				else if defaultType!?0 is \radio
					inputTypes name, defaultType!0 .radio!

				else if defaultType!?0 then m \.field,
					m \label.label,
						m \span, label
						m \span.has-text-danger, \* unless schema.optional
					m \.control, m \input.input,
						class: \is-danger if error
						type: schema.autoform?type or that
						name: name, id: name, value: do ->
							date = abnDoc?[name] and that is \date and
								moment abnDoc[name] .format \YYYY-MM-DD
							state.form[opts.id]?[name] or date or abnDoc?[name]
					m \p.help.is-danger, error if error

				else if schema.type is Object
					sorted = -> reduce [], reverse(maped), (res, inc) ->
						if inc.autoform?type is \hidden then [...res, inc]
						else [inc, ...res]
					filtered = sorted!filter (j) ->
						getLen = (str) -> _.size _.split str, \.
						_.every conds =
							_.includes j.name, "#{normed name}."
							getLen(name)+1 is getLen(j.name)
					m \.box,
						unless +label then m \h5, label
						m \.box, columnize filtered.map -> _.merge it, head: name

				else if schema.type is Array
					found = maped.find -> it.name is "#{normed name}.$"
					docLen = if opts.scope is name then 1 else
						(.length-1) _.filter abnDoc, (val, key) ->
							_.includes key, "#name."
					m \.box,
						unless opts.scope is name then m \div,
							m \h5.subtitle, label
							m \a.button.is-success, attr.arrLen(name, \inc), '+ Add'
							m \a.button.is-warning, attr.arrLen(name, \dec), '- Rem'
						[1 to (state.arrLen[name] or docLen or 0)]map (num) ->
							type = j?autoform?type or \other
							inputTypes "#name.#num", found .[type]!
						m \p.help.is-danger, error if error

		view: -> m \.box, m \form, attr.form,
			m \.row, columnize usedFields.map (i) ->
				_.merge theSchema(i), name: i, head: i

			m \.row, m \.columns,
				m \.column.is-1, m \input.button.is-primary,
					type: \submit
					value: opts?buttonContent
					class: opts?buttonClasses
				m \.column.is-1, m \input.button.is-warning,
					type: \reset
					value: opts?reset?content
					class: opts?reset?classes
