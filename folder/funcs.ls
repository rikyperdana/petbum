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

	@normalize = (obj) ->
		recurse = (value, name) ->
			if _.isObject value
				isNum = _.size _.filter value, (val, key) -> +key+1
				console.log value, name, isNum
				res = "#name":
					if isNum > 0 then _.map value, recurse
					else if value.getMonth then value
					else _.merge {}, ... _.map value, recurse
				if +name then res[name] else res
			else
				if +name+1 then value
				else "#name": value
		obj = recurse obj, \obj .obj
		for key, val of obj
			if key.split(\.)length > 1
				delete obj[key]
		obj

	@autoForm = (opts) ->
		state = afState
		normed = -> it.replace /\d/g, \$

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

		alphabetically = -> _.sortBy it, \label
		optionList = (name) -> alphabetically ors arr =
			theSchema(normed name)?allowedValues?map (i) ->
				value: i, label: _.startCase i
			if _.isFunction theSchema(normed name)?autoform?options
				theSchema(normed name)?autoform?options name, opts.id
			else theSchema(normed name)?autoform?options
			<[true false]>map (i) ->
				value: JSON.parse i
				label: _.startCase i

		state.arrLen ?= {}; state.form ?= {}
		state.temp ?= {}; state.errors ?= {}
		state.form[opts.id] ?= {}; state.temp[opts.id] ?= []
		stateTempGet = (field) -> if state.temp[opts.id]
			_.findLast state.temp[opts.id], -> it.name is field

		clonedDoc = if opts.type is \update-pushArray
			_.assign {}, opts.doc, "#{opts.scope}": []
		usedDoc = clonedDoc or opts.doc

		attr =
			form:
				id: opts.id
				onchange: ({target}) ->
					if opts.onchange then that target
					arr = <[ radio checkbox select ]>
					unless theSchema(target.name)?autoform?type in arr
						state.form[opts.id][target.name] = target.value
					opts.autosave and $ "form##{opts.id}" .submit!

				onsubmit: (e) -> unless afState.disable
					afState.disable = true
					e.preventDefault!
					temp = state.temp[opts.id]map -> "#{it.name}": it.value
					formValues = _.filter e.target, (i) ->
						a = -> (i.value isnt \on) and i.name
						arr = <[ radio checkbox select ]>
						b = -> theSchema(i)?autoform?type in arr
						a! and not b!
					.map ({name, value}) -> if name and value
						_.reduceRight name.split(\.),
							((res, inc) -> "#inc": res)
							if value then switch theSchema(normed name)type
								when String then value
								when Number then +value
								when Date then new Date value

					obj = normalize _.merge ... temp.concat formValues

					context = usedSchema.newContext!
					context.validate _.merge {}, obj, unless opts.scope then (opts.doc or {})
					state.errors[opts.id] = _.merge {}, ... do ->
						a = context._invalidKeys.filter (i) -> ands arr =
							i.type isnt \keyNotInSchema
							!theSchema(normed i.name)?autoValue
						a.map -> "#{it.name}": it.type

					after = (err, res) -> if res
						afState.disable = false
						opts.hooks?after res
					formTypes = (doc) ->
						insert: -> opts.collection.insert (doc or obj), after
						update: -> opts.collection.update usedDoc._id, {$set: (doc or obj)}, after
						method: -> Meteor.call opts.meteormethod, (doc or obj), after
						'update-pushArray': -> opts.collection.update do
							{_id: usedDoc._id}
							{$push: "#{opts.scope}": $each: _.values obj[opts.scope]}
							(err, res) ->
								afState.disable = false
								opts.hooks?after doc if res

					if _.values(state.errors[opts.id])length is 0
						if opts.hooks?before then that obj, (moded) ->
							formTypes(moded)[opts.type]!
						else formTypes![opts.type]!
						afState.form = null; afState.temp = null

			radio: (name, value) ->
				type: \radio, name: name, id: "#name#value"
				checked: value is (stateTempGet(name)?value or usedDoc?[name])
				onchange: -> state.temp[opts.id]push {name, value}

			select: (name) ->
				name: name
				value: stateTempGet(name)?value or _.get usedDoc, name
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
					else if usedDoc?["#name.0"]
						value.toString! in _.compact _.map usedDoc,
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
			title = ors arr =
				theSchema(normed name)?label
				_.startCase _.last _.split (normed name), \.
			label = m \label.label,
				m \span, title
				m \span.has-text-danger, \* unless theSchema(normed name)optional
			error = _.startCase _.find state.errors[opts.id],
				(val, key) -> key is name

			disabled: -> m \div,
				label
				m \input.input,
					name: name, disabled: true, value: ors arr =
						_.get usedDoc, name
						schema.autoValue? name, _.map state.form[opts.id],
							(val, key) -> value: val, name: key

			hidden: -> m \input,
				type: \hidden, name: name, id: name,
				value: schema.autoValue? name, _.map state.form[opts.id],
					(val, key) -> value: val, name: key

			textarea: -> m \div,
				label
				m \textarea.textarea,
					name: name, id: name,
					class: \is-danger if error
					value: state.form[opts.id][name] or usedDoc?[name]
				m \p.help.is-danger, error if error

			range: -> m \div,
				label
				m \input,
					type: \range, id: name, name: name,
					class: \is-danger if error
					value: state.form[opts.id][name] or usedDoc?[name]?toString!
				m \p.help.is-danger, error if error

			checkbox: -> m \.columns,
				label
				optionList(name)map (j) -> m \.column, m \label.checkbox,
					m \input, attr.checkbox name, j.value
					m \span, _.startCase j.label
				m \p.help.is-danger, error if error

			select: -> m \div,
				label
				m \.select, m \select, attr.select(name),
					m \option, value: '', ors arr =
						theSchema(normed name)autoform?firstLabel
						'Select One'
					optionList(name)map (j) ->
						m \option, value: j.value, j.label
				m \p.help.is-danger, error if error

			radio: -> m \.control,
				label
				optionList(normed name)map (j) -> m \label.radio,
					m \input, attr.radio name, j.value
					m \span, _.startCase j.label
				m \p.help.is-danger, error if error

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
					label
					m \.control, m \input.input,
						class: \is-danger if error
						type: schema.autoform?type or that
						name: name, id: name, step: \any, value: ors arr =
							state.form[opts.id]?[name]
							ands arr =
								_.get usedDoc, name
								that is \date
								moment(_.get usedDoc, name)format \YYYY-MM-DD
							_.get usedDoc, name
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
						(.length-1) _.filter usedDoc, (val, key) ->
							_.includes key, "#name."
					m \.box,
						unless opts.scope is name then m \div,
							m \h5.subtitle, label
							m \a.button.is-success, attr.arrLen(name, \inc), '+ Add'
							m \a.button.is-warning, attr.arrLen(name, \dec), '- Rem'
							if state.arrLen[name] then m \.button, that
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
				if opts?reset
					m \.column.is-1, m \input.button.is-warning,
						type: \reset
						value: that?content
						class: that?classes
