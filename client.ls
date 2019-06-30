if Meteor.isClient

	attr =
		layout:
			hospital: 'RSUD Petala Bumi'
			rights: -> modules.filter -> it.name in
				_.flatMap (_.keys Meteor.user!?roles), (i) ->
					(.list) rights.find -> it.group is i
		pageAccess: -> userGroup! in it
		pasien:
			showForm:
				patient: onclick: ->
					state.showAddPatient = not state.showAddPatient
				rawat: onclick: ->
					state.showAddRawat = not state.showAddRawat
			headers:
				patientList: <[ tanggal_terakhir_rawat no_mr nama_lengkap tanggal_lahir tempat_lahir]>
				rawatFields: <[ tanggal_berobat poliklinik cara_bayar dokter bayar_pendaftaran status_bayar ]>
				icdFields: <[ nama_pasien tanggal klinik dokter diagnosis nama_perawat cek ]>
			rawatDetails: (doc) -> arr =
				{head: \Tanggal, cell: hari that if doc.tanggal}
				{head: \Klinik, cell: look(\klinik, doc.klinik)label}
				{head: 'Cara Bayar', cell: look(\cara_bayar, doc.cara_bayar)label}
				{head: 'Anamesa Perawat', cell: doc?anamesa_perawat}
				{head: 'Anamesa Dokter', cell: doc?anamesa_dokter}
				{head: \Diagnosa, cell: doc?diagnosa?join ', '}
				{head: \Planning, cell: doc?planning}
				...[<[tekanan_darah mmHg]> <[nadi pulse]> <[suhu Celcius]> <[pernafasan RR]> <[berat Kg]> <[tinggi cm]> <[lila cm]>]map ->
					{head: "Fisik #{_.startCase it.0}", cell: if doc.fisik?[it.0] then "#that #{it?1 or ''}"}
				...<[penyakit_sebelumnya operasi dirawat pengobatan_dirumah alergi transfusi darah merokok minuman_keras obat_terlarang]>map ->
					{head: "Riwayat #{_.startCase it}", cell: doc.riwayat?[it]}
				...(doc.riwayat?kesehatan?imunisasi or [])map (i, j) ->
					{head: "Imunisasi #{j+1}", cell: look(\imunisasi, i)?label}
				...(doc.riwayat?keluarga or [])map (i, j) ->
					{head: "Penyakit keluarga/hubungan #{j+1}", cell: "#{look(\penyakit, i.penyakit)?label}/#{i.hubungan}"}
				...<[wanita_hamil pria_prostat keikutsertaan_kb]>map ->
					{head: "Reproduksi #{_.startCase it}", cell: if doc.riwayat?reproduksi?[it] then look(\yatidak, that)?label}
				...<[nyeri frekuensi karakteristik_nyeri]>map ->
					{head: "Kenyamanan #{_.startCase it}", cell: look(it, doc.kenyamanan?[it])?label}
				{head: 'Kenyamanan Lokasi', cell: doc.kenyamanan?lokasi}
				{head: 'Status Psikologi', cell: if doc.status_psikologi then look(\psikologi, that)?label}
				...<[bab bak]>map -> {head: "Eliminasi #{_.startCase it}", cell: if doc.eliminasi?[it] then look(it, that)?label}
				...<[bicara hambatan potensial]>map -> {head: "Komunikasi #{_.startCase it}", cell: if doc.komunikasi?[it] then look(it, that)?label}
			currentPasien: -> look2 \pasien, m.route.param \idpasien
			ownKliniks: -> roles!?jalan?map (i) ->
				(.value) selects.klinik.find (j) -> i is _.snakeCase j.label
			list: ->
				byName = 'regis.nama_lengkap':
					$options: \i, $regex: ".*#{state.search or ''}.*"
				byNoMR = no_mr: +(state.search or '')
				(.fetch!) coll.pasien.find $or: [byName, byNoMR]
			lastKlinik: (arr) ->
				unless roles!?jalan then arr
				else if isDr! then arr.filter -> ands list =
					if _.last(it.rawat)dokter then that is Meteor.userId! else true
					_.last(it.rawat)anamesa_perawat
					not _.last(it.rawat)anamesa_dokter
				else arr.filter -> ands list =
					not _.last(it.rawat)anamesa_perawat
					_.last(it.rawat)billRegis
			patientHistory: ->
				_.reverse _.sortBy attr.pasien.currentPasien!rawat, \tanggal
			continuable: -> ands arr =
				it.idrawat is (.idrawat) _.last attr.pasien.currentPasien!rawat
				currentRoute! is \jalan
				if !isDr! then !it.anamesa_perawat else true
				if isDr! then it.anamesa_perawat else true
				if isDr! then !it.anamesa_dokter else true
				userRole! is _.snakeCase look(\klinik, it.klinik)label
			rawatDetails2: (doc) -> m \div,
				m \h1, attr.pasien.currentPasien!regis.nama_lengkap
				m \table.table,
					attr.pasien.rawatDetails doc
					.map (i) -> i.cell and m \tr, [(m \th, i.head), (m \td, i.cell)]
				if doc.tindakan then m \div,
					m \br
					m \table, m \tr, m \th, \Tindakan
					m \table.table,
						that?map (i) -> m \tr, tds arr =
							_.startCase look2(\tarif, i.nama)nama
							rupiah i.harga
						m \tr, (m \th, \Total), m \td,
							rupiah _.sum that.map -> it.harga
				if doc.obat then m \div,
					m \br
					m \table, m \tr, m \th, \Obat
					m \table.table, that.map (i) -> m \tr, tds arr =
						_.startCase look2(\gudang, i.nama)nama
						if i.aturan?kali then "#that kali"
						if i.aturan?dosis then "#that dosis"
						"#{i.jumlah} unit"
						if i.puyer then "puyer #that"
		bayar: header: <[ no_mr nama tanggal cara_bayar klinik aksi ]>
		apotik: header: <[ no_mr nama tanggal cara_bayar klinik aksi ]>
		farmasi:
			headers:
				farmasi: <[ jenis_barang nama_barang satuan batas_depook batas_apotik batas_gudang stok_diapotik stok_didepook stok_gudang ]>
				rincian: <[ nobatch digudang diapotik didepook masuk kadaluarsa ]>
			currentBarang: -> look2 \gudang, m.route.param \idbarang
			fieldSerah: <[ nama_obat jumlah_obat aturan_kali aturan_dosis ]>
			search: -> it.filter (i) -> ors <[nama kandungan]>map (j) ->
				_.includes (_.lowerCase i[j]), _.lowerCase state.search
		manajemen:
			headers: tarif: <[ nama harga first second third active ]>
			userList: -> pagins _.reverse ors arr =
				if state.search then _.concat do
					Meteor.users.find!fetch!filter (i) -> ors <[keys values]>map (j) ->
						_.includes (_.join _[j] i.roles), that
					Meteor.users.find(username: $regex: ".*#that.*")fetch!
				Meteor.users.find!fetch!
		amprah:
			headers: requests: <[ tanggal_minta ruangan peminta jumlah nama_barang penyerah diserah tanggal_serah]>
			amprahList: ->
				reverse coll.amprah.find!fetch!filter (i) ->
					if userGroup \jalan then i.ruangan is userRole!
					else if not userGroup \farmasi then i.ruangan is userGroup!
					else i
			buttonConds: (obj) -> ands arr =
				not obj.diserah
				userGroup! is \farmasi
				not same [userGroup!, obj.ruangan]
			reqForm: -> arr =
				\bhp unless userGroup \farmasi
				if userGroup! in <[obat inap depook]> then \obat
			available: ->
				_.sum look2(\gudang, state.modal.nama)batch.map (i) ->
					if userGroup \farmasi then i.digudang
					else i.diapotik

	loginComp = -> view: -> m \.container, m \.columns,
		m \.column
		m \.column,
			m \.content, m \h4, \Login
			m \form,
				onsubmit: (e) ->
					e.preventDefault!
					vals = _.initial _.map e.target, -> it.value
					Meteor.loginWithPassword ...vals, (err) ->
						if err
							state.error = 'Salah Password atau Username'
							m.redraw!
						else m.route.set \/dashboard
				m \input.input, type: \text, placeholder: \Username
				m \input.input, type: \password, placeholder: \Password
				m \input.button.is-success, type: \submit, value: \Login
				if state.error then m \article.message, m \.message-header,
					(m \p, that), m \button.delete, 'aria-label': \delete
		m \.column

	comp =
		layout: (comp) -> view: -> m \div,
			m \link, rel: \stylesheet, href: 'https://use.fontawesome.com/releases/v5.8.1/css/all.css'
			m \nav.navbar.is-info,
				role: \navigation, 'aria-label': 'main navigation',
				m \.navbar-brand, m \a.navbar-item,
					href: \/dashboard
					oncreate: m.route.link
					style: "margin-left: 600px"
					_.upperCase (?full or attr.layout.hospital) modules.find ->
						it.name is m.route.get!split \/ .1
				m \.navbar-end, m \.navbar-item.has-dropdown,
					class: \is-active if state.userMenu
					m \a.navbar-link,
						onclick: -> state.userMenu = not state.userMenu
						m \span, m \i.fa.fa-user, style: "padding-right: 5px"
						m \span, Meteor.user!?username
					m \.navbar-dropdown.is-right, do ->
						logout = -> arr =
							Meteor.logout!
							m.route.set \/login
							m.redraw!
						arr =
							if Meteor.user!?roles then ["Grup: #{userGroup!}, Peran: #{userRole!}", \user-tag] else ['']
							unless Meteor.userId! then [\Login, \sign-in-alt', -> m.route.set \/login]
							else [\Logout, \sign-out-alt, -> logout!]
						arr.map (i) -> m \a.navbar-item,
							onclick: i?2
							m \span.icon.is-small, m "i.fa.fa-#{i?1}", style: "padding-right: 5px"
							m \span, i?0
			m \.columns,
				Meteor.userId! and m \.column.is-2, m \aside.menu.box,
					m \p.menu-label, 'Admin Menu'
					m \ul.menu-list, attr.layout.rights!map (i) -> m \li,
						oncreate: ->
							args = name: i.name, params: arr =
								userRole! if userGroup \jalan
								isDr! if userGroup \jalan
							Meteor.call \notify, args, (err, res) -> if res
								state.notify[i.name] = res
								m.redraw!
						m \a,
							href: "/#{i.name}"
							oncreate: m.route.link
							class: \is-active if state.activeMenu is i.name
							m \span.icon.is-small, m "i.fa.fa-#{i.icon}"
							m \span, "    #{i.full} #{state.notify?[i.name] or ''}"
						if attr.pageAccess(<[regis jalan]>) then
							if \regis is currentRoute! then m \ul,
								[[\lama, 'Cari Pasien'], [\baru, 'Pasien Baru']]map (i) ->
									m \li, m \a, {
										href: "/regis/#{i.0}"
										oncreate: m.route.link
									}, _.startCase i.1
						if same [\manajemen, currentRoute!, i.name]
							m \ul, <[ users imports ]>map (i) -> m \li, m \a,
								href: "/manajemen/#i"
								oncreate: m.route.link
								m \span, _.startCase i
				m \.column,
					unless Meteor.userId! then m loginComp
					else if comp then m that

		login: loginComp

		welcome: -> view: -> m \.content,
			oncreate: -> Meteor.subscribe \users, (err, res) -> res and m.redraw!
			m \h1, "Panduan bagi #{(?full) modules.find -> it.name is userGroup!}"
			m \div, guide userGroup!, userRole!

		pasien: -> view: -> if attr.pageAccess(<[regis jalan]>) then m \.content,
			oncreate: Meteor.subscribe \coll, \daerah, $and: arr =
				{provinsi: $exists: true}
				{kabupaten: $exists: false}
			if userGroup \regis and userRole \admin then elem.report do
				title: 'Laporan Kunjungan Poliklinik'
				action: ({start, end, type}) -> if start and end
					Meteor.call \visits, {start, end}, (err, res) -> if res
						title = "Kunjungan #{hari start} - #{hari end}"
						obj = Excel: csv, Pdf: makePdf.csv
						obj[type] title, that
			if m.route.param(\jenis) in <[baru edit]> then m autoForm do
				collection: coll.pasien
				schema: new SimpleSchema schema.regis
				type: if m.route.param(\idpasien) then \update else \insert
				id: \formRegis
				doc: attr.pasien.currentPasien!
				buttonContent: \Simpan
				columns: 3
				onchange: (doc) ->
					if doc.name is \no_mr
						Meteor.call \onePasien, {no_mr: doc.value}, (err, res) ->
							if res then afState.errors.formRegis = no_mr: \Terpakai
							else delete afState.errors.formRegis.no_mr
							m.redraw!
					else if doc.name is \regis.provinsi
						Meteor.subscribe \coll, \daerah, $and: arr =
							{provinsi: +doc.value}
							{kabupaten: $exists: true}
					else if doc.name is \regis.kabupaten
						Meteor.subscribe \coll, \daerah, $and: arr =
							{kabupaten: +doc.value}
							{kecamatan: $exists: true}
					else if doc.name is \regis.kecamatan
						Meteor.subscribe \coll, \daerah, $and: arr =
							{kecamatan: +doc.value}
							{kelurahan: $exists: true}
				hooks:
					before: (doc, cb) ->
						if \edit is m.route.param \jenis then cb doc
						else Meteor.call \onePasien, {no_mr: doc.no_mr}, (err, res) ->
							unless res then cb doc
					after: (id) ->
						state.showAddPatient = null
						if id is 1 then m.route.set "/regis/lama/#{m.route.param \idpasien}"
						else m.route.set "/regis/lama/#id"
			if userRole(\mr) then m \div,
				m \br, oncreate: ->
					Meteor.subscribe \coll, \tarif
					Meteor.subscribe \users
				m \form.columns,
					onsubmit: (e) ->
						e.preventDefault!
						Meteor.call \onePasien, {no_mr: e.target.0.value}, (err, res) ->
							makePdf.icdx res if res
					m \.column, m \input.input, type: \text, placeholder: 'No MR Pasien'
					m \.column, m \input.button.is-primary, type: \submit, value: \Unduh
				m \h4, 'Kodifikasi ICD 10'
				m \table.table,
					oncreate: -> Meteor.subscribe \coll, \pasien,
						{rawat: $elemMatch: $and: [
							{'anamesa_dokter': $exists: true}
							{icdx: $exists: false}
						]}
						onReady: -> m.redraw!
					m \thead, attr.pasien.headers.icdFields.map (i) -> m \th, _.startCase i
					m \tbody, coll.pasien.find!fetch!map (i) -> i.rawat.map (j) ->
						if j.anamesa_dokter and not j.icdx then m \tr, tds arr =
							i.regis.nama_lengkap
							hari j.tanggal
							look(\klinik, j.klinik)label
							_.startCase Meteor.users.findOne(j.petugas.dokter)username
							j.diagnosa?0
							_.startCase Meteor.users.findOne(j.petugas.perawat)username
							m \.button.is-info,
								onclick: -> state.modal = _.merge rawat: j, pasien: i
								m \span, \Cek
				if state.modal then elem.modal do
					title: 'Kodekan ICD 10'
					content: m \div,
						m \table.table, that.rawat.diagnosa.map (i, j) ->
							m \tr, [(m \td, j+1), (m \td, _.startCase i)]
						m autoForm do
							schema: new SimpleSchema icdx: type: [String]
							type: \method
							meteormethod: \icdX
							hooks:
								before: (doc, cb) -> cb _.merge {}, doc,
									idpasien: state.modal.pasien._id
									rawat: state.modal.rawat
								after: ->
									state.modal = null
									m.redraw!
			else if m.route.get! in ['/regis/lama', '/jalan'] then m \div,
				userGroup(\regis) and m \form,
					onsubmit: (e) ->
						e.preventDefault!
						val = e.target.0.value
						if val.length > 3
							byName = 'regis.nama_lengkap':
								$options: \-i, $regex: ".*#val.*"
							byNoMR = no_mr: +val
							state.search = val
							Meteor.subscribe \coll, \pasien, {$or: [byName, byNoMR]},
								{limit: 30}, onReady: -> m.redraw!
					m \input.input, type: \text, placeholder: \Pencarian
				m \table.table,
					oncreate: -> Meteor.subscribe \users, onReady: ->
						onKlinik = rawat: $elemMatch: klinik: $in: attr.pasien.ownKliniks!
						Meteor.subscribe \coll, \pasien, onKlinik, onReady: -> m.redraw!
					m \thead, m \tr, [...attr.pasien.headers.patientList, \ibu]map (i) ->
						m \th, _.startCase i
					m \tbody, attr.pasien.lastKlinik(attr.pasien.list!)map (i) ->
						rows = -> if i.no_mr then m \tr,
							ondblclick: -> m.route.set "#{m.route.get!}/#{i._id}"
							tds arr =
								if i.rawat?[i.rawat?length-1]?tanggal then hari that
								i.no_mr
								i.regis.nama_lengkap
								if i.regis.tgl_lahir then moment(that)format 'D MMM YYYY'
								if i.regis.tmpt_lahir then _.startCase that
								i.regis?ibu
						if currentRoute! is \jalan
							if i.rawat?reverse!?0?billRegis then rows!
						else rows!
				if userGroup(\jalan) and !isDr! then m \div,
					[til 2]map -> m \br
					m \h4, 'Daftar Antrian Panggilan Dokter'
					m \table.table,
						m \thead, m \tr, attr.pasien.headers.patientList.map (i) ->
							m \th, _.startCase i
						m \tbody, coll.pasien.find!fetch!map (i) ->
							doneByNurse = -> ands arr =
								i.rawat[i.rawat.length-1]anamesa_perawat
								not i.rawat[i.rawat.length-1]anamesa_dokter
							if doneByNurse! then m \tr, tds arr =
								hari i.rawat[i.rawat.length-1]tanggal
								i.no_mr
								i.regis.nama_lengkap
								hari i.regis.tgl_lahir
								i.regis.tmpt_lahir
			else if m.route.param \idpasien then m \div,
				oncreate: ->
					Meteor.subscribe \users
					Meteor.subscribe \coll, \tarif
					Meteor.subscribe \coll, \gudang
					Meteor.subscribe \coll, \pasien,
						{_id: m.route.param \idpasien}, onReady: ->
							m.redraw! and Meteor.call \regions,
								attr.pasien.currentPasien!regis
								(err, res) ->
									state.regions = res
									m.redraw!
							m.redraw!
				[til 2]map -> m \br
				m \.content, m \h4, 'Rincian Pasien'
				if doc = attr.pasien.currentPasien! then m \div,
					m \table.table, _.chunk([
						{name: 'No. MR', data: doc.no_mr}
						{name: 'Nama Lengkap', data: doc.regis.nama_lengkap}
						{name: 'Tanggal Lahir', data: hari doc.regis.tgl_lahir}
						{name: 'Tempat Lahir', data: doc.regis.tmpt_lahir}
						{name: 'Jenis kelamin', data: look(\kelamin, that)label if doc.regis.kelamin}
						{name: \Agama, data: look(\agama, that)label if doc.regis.agama}
						{name: 'Status nikah', data: look(\nikah, that)label if doc.regis.nikah}
						{name: 'Pendidikan terakhir', data: look(\pendidikan, that)label if doc.regis.pendidikan}
						{name: 'Golongan Darah', data: look(\darah, that)label if doc.regis.darah}
						{name: 'Pekerjaan terakhir', data: look(\pekerjaan, that)label if doc.regis.pekerjaan}
						{name: 'Tempat Tinggal', data: doc.regis.alamat}
						{name: 'Umur', data: moment!diff(doc.regis.tgl_lahir, \years) + ' tahun'}
						{name: 'Nama Bapak', data: doc.regis.ayah}
						{name: 'Nama Ibu', data: doc.regis.ibu}
						{name: 'Suami/Istri', data: doc.regis.pasangan}
						{name: \Kontak, data: doc.regis.kontak}
						{name: \Provinsi, data: _.startCase that if state.regions.provinsi}
						{name: \Kabupaten, data: _.startCase that if state.regions.kabupaten}
						{name: \Kecamatan, data: _.startCase that if state.regions.kecamatan}
						{name: \Kelurahan, data: _.startCase that if state.regions.kelurahan}
					], 4)map (i) -> m \tr, i.map (j) -> [(m \th, j.name), (m \td, j.data)]
					if currentRoute! is \regis then m \div, [
						[\Kartu, \is-info, onclick: -> makePdf.card m.route.param \idpasien]
						[\Consent, \is-info, onclick: -> makePdf.consent!]
						[\Edit, \is-warning, onclick: -> m.route.set "/regis/edit/#{m.route.param \idpasien}"]
						['+Rawat Jalan', \is-success, attr.pasien.showForm.rawat ]
					]map (i) -> m ".button.#{i.1}", (_.merge style: 'margin-right: 10px', i.2), i.0
					if currentRoute! is \jalan
						m \button.button.is-warning,
							onclick: -> state.rekapRawat = attr.pasien.currentPasien!rawat
							'Rekap Rawat'
					state.rekapRawat and elem.modal do
						title: 'Rekap Riwayat Rawat Pasien'
						content: m \div, state.rekapRawat.map -> attr.pasien.rawatDetails2 it
						noClose: true
						danger: \Tutup
						dangerAction: -> state.rekapRawat = null
					state.showAddRawat and m autoForm do
						collection: coll.pasien
						schema: new SimpleSchema schema.rawatRegis
						type: \update-pushArray
						id: \formJalan
						scope: \rawat
						doc: attr.pasien.currentPasien!
						buttonContent: \Simpan
						columns: 3
						hooks:
							before: (doc, cb) -> cb rawat:
								[_.merge doc.rawat.0, petugas: "#{userGroup!}": Meteor.userId!]
							after: ->
								state.showAddRawat = false
								m.redraw!
					[til 2]map -> m \br
					state.docRawat and m \.content,
						m \h4, 'Rincian Rawat'
						m \table.table,
							attr.pasien.rawatDetails attr.pasien.currentPasien!rawat.find(-> it.idrawat is state.docRawat)
							.map (i) -> i.cell and m \tr, [(m \th, i.head), (m \td, i.cell)]
					state.docRawat and m autoForm do
						collection: coll.pasien
						schema: new SimpleSchema do
							if isDr! then schema.rawatDoctor
							else schema.rawatNurse
						type: \update-pushArray
						id: \formRawat
						scope: \rawat
						doc: attr.pasien.currentPasien!
						buttonContent: \Simpan
						columns: 3
						hooks:
							before: (doc, cb) ->
								base = attr.pasien.currentPasien!rawat.find -> it.idrawat is state.docRawat
								obj =
									idpasien: attr.pasien.currentPasien!_id
									idrawat: state.docRawat
								Meteor.call \rmRawat, obj, (err, res) -> res and cb _.merge doc.rawat.0, base,
									petugas: "#{if isDr! then \dokter else \perawat}": Meteor.userId!
									first: true if attr.pasien.currentPasien!rawat.length is 0
									status_bayar: true if ors arr =
										base.cara_bayar isnt 1
										ands arr =
											doc.rawat.0.obat
											not doc.rawat.0.tindakan
							after: (doc) ->
								if doc.pindah then coll.pasien.update do
									{_id: m.route.param \idpasien},
									$push: rawat:
										klinik: that
										billRegis:
											if doc.cara_bayar is 1 then false
											else true
										cara_bayar: doc.cara_bayar
										idrawat: randomId!
										petugas: doc.petugas
										tanggal: new Date!
								state.docRawat = null
								m.redraw!
					m \table.table,
						m \thead, m \tr,
							attr.pasien.headers.rawatFields.map (i) ->
								m \th, _.startCase i
							m \th, \Rincian if userGroup \jalan
							m \th, \Hapus if userRole \admin
						# m \tbody, pagins attr.pasien.currentPasien!rawat?map (i) -> m \tr, [
						m \tbody, pagins attr.pasien.patientHistory!map (i) -> m \tr, [
							hari i.tanggal
							look(\klinik, i.klinik)label
							look(\cara_bayar, i.cara_bayar)label
							if i.dokter then _.startCase Meteor.users.findOne(that)?username
							... <[ billRegis status_bayar ]>map ->
								if i[it] then \Sudah else \Belum
							if userGroup \jalan then m \button.button.is-info,
								onclick: ->
									if attr.pasien.continuable i then state.docRawat = i.idrawat
									else state.modal = i
								m \span, if attr.pasien.continuable i then \Lanjutkan else \Lihat
							if userRole \admin then m \.button.is-danger,
								ondblclick: -> Meteor.call \rmRawat,
									{idpasien: m.route.param \idpasien, idrawat: i.idrawat}
									(err, res) -> res and m.redraw!
								m \span, \Hapus
						]map (j) -> m \td, j or \-
						elem.pagins!
					if state.modal then elem.modal do
						title: 'Rincian rawat'
						content: attr.pasien.rawatDetails2 state.modal
						action: ->
							state.docRawat = state.modal.idrawat
							state.spm = new Date!
							state.modal = null
			else m \div
		regis: -> this.pasien
		jalan: -> this.pasien

		bayar: -> view: -> if attr.pageAccess(<[bayar]>) then m \.content,
			m \table.table,
				oncreate: ->
					Meteor.subscribe \coll, \tarif
					Meteor.subscribe \coll, \gudang
					Meteor.subscribe \coll, \pasien,
						{rawat: $elemMatch: $or: [
							{billRegis: $ne: true}
							{status_bayar: $ne: true}
						]}
						onReady: -> m.redraw!
				m \thead, m \tr, attr.bayar.header.map (i) -> m \th, _.startCase i
				m \tbody, coll.pasien.find!fetch!map (i) -> _.compact i.rawat.map (j) ->
					conds = ors arr =
						not j.billRegis
						if j.tindakan then not j.status_bayar
						j.obat and j.givenDrug and !j.paidDrug
					if j.cara_bayar is 1 then if conds then m \tr, [
						i.no_mr, i.regis.nama_lengkap,
						hari j.tanggal
						look(\cara_bayar, j.cara_bayar)label
						look(\klinik, j.klinik)label
						m \a.button.is-success,
							onclick: -> state.modal = _.merge j, pasienId: i._id
							m \span, \Bayar
					]map (k) -> m \td, k
			if state.modal
				tindakans = state.modal.tindakan?map -> arr =
					_.startCase look2(\tarif, it.nama)nama
					it.harga
				obats = state.modal.obat?map -> arr =
					"#{_.startCase look2(\gudang, it.nama)nama} x #{it.jumlah}"
					1.25 * it.jumlah * _.max look2(\gudang, it.nama)batch.map -> it.beli
				uraian = if state.modal.givenDrug then obats or [] else arr =
					['Cetak Kartu', 10000] if ands arr =
						not coll.pasien.findOne(state.modal.pasienId)rawat?0?billRegis
						coll.pasien.findOne(state.modal.pasienId)regis.petugas
					['Konsultasi Spesialis', look(\karcis, that.klinik)label*1000] unless state.modal.billRegis
					... tindakans or []
				params = <[ pasienId idrawat ]>map -> state.modal[it]
				elem.modal do
					title: 'Sudah bayar?'
					content: m \table.table,
						uraian.map (i) -> if i then m \tr, [(m \th, i.0), (m \td, rupiah i.1)]
						m \tr, [(m \th, 'Total Biaya'), (m \td, rupiah _.sum uraian.map -> it?1)]
					confirm: \Sudah
					action: -> Meteor.call \updateArrayElm,
						name: \pasien, recId: that.pasienId, scope: \rawat,
						elmId: that.idrawat, doc: _.merge that,
							if !that.billRegis then billRegis: true
							else if !that.status_bayar then status_bayar: true
							else if that.givenDrug then paidDrug: true
						(err, res) -> if res
							unless state.modal.anamesa_perawat
								makePdf.payRegCard ...params, _.compact uraian
							else makePdf.payRawat ...params, _.compact uraian
							state.modal = null
							m.redraw!
			if userRole \admin then elem.report do
				title: 'Laporan Pemasukan'
				action: ({start, end, type}) -> if start and end
					Meteor.call \incomes, {start, end}, (err, res) -> if res
						title = "Pemasukan #{hari start} - #{hari end}"
						header = ['No. MR', 'Nama Pasien', \Tanggal, \Poliklinik, 'No. Karcis', \Kartu, \Karcis, \Tindakan, \Obat, \Total]
						obj = Excel: csv, Pdf: makePdf.csv
						obj[type] title, that, [header]

		obat: -> view: -> if attr.pageAccess(<[obat depook]>) then m \.content,
			oncreate: -> Meteor.subscribe \users
			m \h4, \Apotik
			m \button.button.is-success,
				onclick: -> state.showForm = not state.showForm
				m \span, 'Billing Obat'
			if state.showForm then m autoForm do
				schema: new SimpleSchema schema.bypassObat
				type: \method
				meteormethod: \serahObat
				id: \formSerahObat
				columns: 4
				hooks:
					before: (doc, cb) -> cb _.merge doc, source: userGroup!
					after: (doc) ->
						coll.rekap.insert _.merge doc.0, source: userGroup!
						makePdf.ebiling doc.0
						afState.form = {}; afState.arrLen = {}
						state.showForm = false
						m.redraw!
			m \table.table,
				oncreate: ->
					Meteor.subscribe \coll, \gudang
					Meteor.subscribe \coll, \rekap, printed: $exists: false
					Meteor.subscribe \coll, \pasien,
						{rawat: $elemMatch: obat: $elemMatch: hasil: $exists: false}
						onReady: -> m.redraw!
				m \thead, attr.apotik.header.map (i) -> m \th, _.startCase i
				m \tbody, coll.pasien.find!fetch!map (i) -> i.rawat.map (j) ->
					okay = -> ands arr =
						j.obat
						if j.cara_bayar is 1
							j.status_bayar and not j.givenDrug
						else not j.givenDrug
					okay! and m \tr, tds arr =
						i.no_mr
						i.regis.nama_lengkap
						hari j.tanggal
						look(\cara_bayar, j.cara_bayar)label
						look(\klinik, j.klinik)label
						m \.button.is-success,
							onclick: -> state.modal = _.merge j, i
							m \span, \Serah
			if state.modal then elem.modal do
				title: 'Serahkan Obat?'
				content: m \table.table,
					m \tr, attr.farmasi.fieldSerah.map (i) ->
						m \th, _.startCase i
					that.obat.map (i) -> m \tr, tds arr =
						look2(\gudang, i.nama)nama
						"#{i.jumlah} unit"
						if i.aturan?kali then "#that kali"
						if i.aturan?dosis then "#that unit"
				confirm: \Serahkan
				action: ->
					doc = _.assign state.modal, source: userGroup!
					Meteor.call \serahObat, doc, (err, res) -> if res
						coll.pasien.update state.modal._id, $set: rawat:
							state.modal.rawat.map (i) ->
								unless i.idrawat is state.modal.idrawat then i else
									_.assign givenDrug: true, _.omit i, <[_id no_mr regis]>
						res.map ->
							coll.rekap.insert _.merge it,
								idrawat: state.modal.idrawat
								tanggal: new Date!
								source: userGroup!
							makePdf.ebiling it
						state.modal = null
						m.redraw!
			[til 2]map -> m \br
			m \.button.is-warning,
				onclick: -> Meteor.subscribe \coll, \pasien,
					{_id: $in: coll.rekap.find!fetch!map -> it.idpasien}
					onReady: -> makePdf.rekap userGroup!
				m \span, "Cetak #{coll.rekap.find!fetch!length} Rekap"
			[til 3]map -> m \br
			if userRole \admin then elem.report do
				title: 'Laporan Pengeluaran Obat'
				action: ({start, end, type}) -> if start and end
					Meteor.call \dispenses, {start, end, source: userGroup!}, (err, res) -> if res
						opts = obat: \Apotik, farmasi: 'Gudang Farmasi', depook: 'Depo OK'
						title = "Pengeluaran Obat #{opts[userGroup!]} #{hari start}-#{hari end}"
						makePdf.csv title, res

		depook: -> this.obat

		farmasi: -> view: -> if attr.pageAccess(<[jalan inap obat farmasi depook]>) then m \.content,
			oncreate: -> state.showForm = batch: false
			if (userGroup \farmasi) and userRole(\admin) then elem.report do
				title: 'Laporan Stok Barang'
				action: ({start, end, type}) -> if start and end
					Meteor.call \stocks, {start, end}, (err, res) -> if res
						title = "Stok Barang Farmasi #{hari start} - #{hari end}"
						obj = Excel: csv, Pdf: makePdf.csv
						obj[type] title, that
			unless m.route.param(\idbarang) then m \div,
				if userGroup! in <[obat farmasi depook]>
					jumlah = (.length) coll.gudang.find!fetch!filter ->
						if userGroup \obat then not it.treshold?apotik
						else if userGroup \depook then not it.treshold?depook
						else if userGroup \farmasi then not it.treshold?gudang
					if jumlah > 0 then m \.notification.is-warning,
						m \button.delete
						m \b, "Terdapat #jumlah barang yang belum diberi ambang batas"
				do ->
					sumA = (.length) coll.gudang.find!fetch!filter (i) -> if i.treshold
						if userGroup \depook then i.treshold.depook > _.sumBy i.batch, \didepook
						else if userGroup \obat then i.treshold.apotik > _.sumBy i.batch, \diapotik
						else if userGroup \farmasi then i.treshold.gudang > _.sumBy i.batch, \digudang
					if sumA > 0 then m \.notification.is-danger,
						m \button.delete
						m \b, "Terdapat #sumA barang yang stoknya dibawah batas"
				m \form,
					onsubmit: (e) ->
						e.preventDefault!
						state.search = _.lowerCase e.target.0.value
					m \input.input, type: \text, placeholder: \Pencarian
				m \br
				if roles!?farmasi then m \button.button.is-success,
					onclick: -> state.showFormFarmasi = not state.showFormFarmasi
					m \span, '+Tambah Jenis Barang'
				if state.showFormFarmasi
					m \h4, 'Form Barang Farmasi'
					m autoForm do
						collection: coll.gudang
						schema: new SimpleSchema schema.farmasi
						type: \insert
						id: \formFarmasi
						buttonContent: \Simpan
						columns: 3
						hooks: after: ->
							state.showFormFarmasi = null
							m.redraw!
				m \table.table,
					oncreate: -> Meteor.subscribe \coll, \gudang, onReady: -> m.redraw!
					m \thead, m \tr, attr.farmasi.headers.farmasi.map (i) ->
						m \th, _.startCase i
					m \tbody, attr.farmasi.search(coll.gudang.find!fetch!)map (i) -> m \tr,
						class: \has-text-danger if do ->
							if userGroup \obat then i.treshold?apotik > _.sumBy i.batch, \diapotik
							else if userGroup \depook then i.treshold?depook > _.sumBy i.batch, \didepook
							else if userGroup \farmasi then i.treshold?gudang > _.sumBy i.batch, \digudang
						ondblclick: -> m.route.set "/farmasi/#{i._id}"
						m \td, look(\barang, i.jenis)?label
						m \td, i.nama
						m \td, look(\satuan, i.satuan)?label
						m \td, i.treshold?depook
						m \td, i.treshold?apotik
						m \td, i.treshold?gudang
						<[ diapotik didepook digudang ]>map (j) ->
							m \td, _.sumBy i.batch, j
			else m \div,
				oncreate: -> Meteor.subscribe \coll, \gudang,
					{_id: m.route.param \idbarang}
					onReady: -> m.redraw!
				m \h4, 'Rincian Obat'
				m \table.table,
					if attr.farmasi.currentBarang! then _.chunk([
						{name: 'Nama Barang', cell: that.nama}
						{name: 'Jenis Barang', cell: look(\barang, that.jenis)label}
						{name: \Kandungan, cell: that.kandungan}
						{name: \Satuan, cell: look(\satuan, that.satuan)label}
						{name: \Fornas, cell: if that.fornas then \Ya else \Tidak}
					], 3)map (i) -> m \tr, i.map (j) -> [(m \th, j.name), (m \td, j.cell)]
					m \tr,
						ondblclick: -> if userGroup! in <[obat farmasi depook]>
							state.modal = attr.farmasi.currentBarang!
						m \th, 'Batas min. Apotik'
						m \td, that?treshold?apotik
						m \th, 'Batas min. Depo OK'
						m \td, that?treshold?depook
						m \th, 'Batas min. Gudang'
						m \td, that?treshold?gudang
				state.modal?_id and elem.modal do
					title: 'Tetapkan Batas min.'
					content: m \div,
						m \h4, 'Berapa batas minimum yang seharusnya tersedia?'
						m \form,
							onsubmit: (e) ->
								e.preventDefault!
								opts = obat: \apotik, farmasi: \gudang, depook: \depook
								coll.gudang.update state.modal._id, $set: treshold: _.merge do
									attr.farmasi.currentBarang!treshold
									"#{opts[userGroup!]}": +e.target.0.value
								state.modal = null
								m.redraw!
							m \.field, m \.control, m \input.input,
								type: \number, placeholder: \Minimum
							m \.field, m \.control, m \input.button.is-success,
								type: \submit, value: \Tetapkan
				if roles!?farmasi then m \.button.is-warning,
					onclick: -> state.showForm.batch = not state.showForm.batch
					m \span,'+Tambahkan Batch'
				if state.showForm?batch then m autoForm do
					collection: coll.gudang
					schema: new SimpleSchema schema.farmasi
					type: \update-pushArray
					scope: \batch
					doc: attr.farmasi.currentBarang!
					id: \formTambahObat
					buttonContent: \Tambahkan
					columns: 3
					hooks: after: ->
						Meteor.call \sortByDate, idbarang: m.route.param \idbarang
						state.showForm.batch = null
						m.redraw!
				m \table.table,
					m \thead, attr.farmasi.headers.rincian.map (i) ->
						m \th, _.startCase i
					m \tbody, attr.farmasi.currentBarang!?batch.map (i) -> m \tr,
						ondblclick: ->
							state.modal = i
							m.redraw!
						tds [i.nobatch, i.digudang, i.diapotik, i.didepook, (hari i.masuk), (hari i.kadaluarsa)]
				if state.modal?idbatch then elem.modal do
					title: 'Rincian Batch'
					content: m \table, do ->
						contents =
							['No. Batch', state.modal.nobatch]
							[\Merek, state.modal?merek]
							['Tanggal Masuk', hari state.modal.masuk]
							['Tanggal Kadaluarsa', hari state.modal.kadaluarsa]
							['Stok di Gudang', "#{state.modal.digudang} unit"]
							['Harga Beli', rupiah state.modal?beli]
							['Harga Jual', rupiah state.modal?jual]
							['Nama Supplier', state.modal?suplier]
							['Bisa diretur', if state.modal?returnable then \Bisa else \Tidak]
							['Sumber Anggaran', look \anggaran, state.modal?anggaran .label]
							['Tahun Pengadaan', state.modal?pengadaan]
						contents.map (i) -> m \tr,
							m \td, m \b, i.0
							m \td, i?1

		manajemen: -> view: -> if attr.pageAccess(<[manajemen]>)
			if \users is m.route.param \subroute then m \.content,
				oncreate: -> Meteor.subscribe \users, onReady: -> m.redraw!
				m \h1, 'Manajemen Pengguna'
				m \h4, 'Tambahkan pengguna baru'
				m \form,
					onsubmit: (e) ->
						e.preventDefault!
						vals = _.initial _.map e.target, -> it.value
						if vals.1 is vals.2 then Meteor.call \newUser,
							{username: vals.0, password: vals.1}
							(err, res) -> res and m.redraw!
					m \.columns, [
						{type: \text, place: \Username}
						{type: \password, place: \Password}
						{type: \password, place: 'Ulangi password'}
					]map (i) -> m \.column, m \.field, m \.control, m \input.input,
						type: i.type, placeholder: i.place
					m \.field, m \.control, m \input.button.is-success,
						type: \submit, value: \Daftarkan
				[til 2]map -> m \br
				m \h4, 'Daftar Pengguna Sistem'
				m \form,
					onkeypress: (e) -> state.search = e.target.value
					m \input.input, type: \text, placeholder: \Pencarian
				m \table.table,
					oncreate: -> Meteor.subscribe \users, onReady: -> m.redraw!
					m \thead, m \tr, <[ Username Peran Profil Aksi ]>map (i) -> m \th, i
					m \tbody, attr.manajemen.userList!map (i) -> m \tr,
						m \td, i.username
						m \td,
							onclick: -> state.modal = _.merge i, type: \role
							m \span, JSON.stringify i.roles
						m \td, m \button.button.is-info,
							onclick: -> state.modal = _.merge i, type: \profil
							m \span, \Profil
						m \td, m \.button.is-danger,
							onclick: -> Meteor.call \rmRole, id: i._id
							m \span, \Reset
					if state.modal?type is \role then elem.modal do
						title: 'Berikan Peranan'
						content: m autoForm do
							schema: new SimpleSchema schema.addRole
							type: \method
							meteormethod: \addRole
							id: \formAddRole
							buttonContent: \Beri
							columns: 3
							hooks:
								before: (doc, cb) ->
									cb _.merge doc, id: state.modal._id
								after: ->
									state.modal = null
									m.redraw!
					else if state.modal?type is \profil then elem.modal do
						title: 'Profil Akun'
						content: m \div,
							m \table, <[nama_lengkap nik]>map (i) -> m \tr,
								m \th, _.startCase i
								m \td, Meteor.users.findOne(state.modal._id)?profile?[i]
							m autoForm do
								schema: new SimpleSchema do
									nama_lengkap: type: String
									nik: type: Number
								type: \method
								meteormethod: \userProfile
								id: \userProfile
								hooks:
									before: (doc, cb) ->
										cb _.merge doc, id: state.modal._id
									after: ->
										state.modal = null
										m.redraw!
				elem.pagins!
			else if \imports is m.route.param \subroute then m \.content,
				m \h1, 'Importer Data'
				m \h4, 'Unggah data csv'
				m \.file, m \label.file-label,
					m \input.file-input, type: \file, name: \csv, onchange: (e) ->
						Papa.parse e.target.files.0, header: true, step: (result) ->
							data = result.data.0
							if data.no_mr
								sel = no_mr: +data.no_mr
								opt = regis:
									nama_lengkap: _.startCase _.lowerCase data.nama_lengkap
									alamat: _.startCase _.lowerCase that if data.alamat
									agama: +that if data.agama
									ayah: _.startCase _.lowerCase that if data.ayah
									nikah: +that if data.nikah
									pekerjaan: +that if data.pekerjaan
									pendidikan: +that if data.pendidikan
									tgl_lahir: new Date that if Date.parse that if data.tgl_lahir
									tmpt_lahir: _.startCase _.lowerCase that if data.tmpt_lahir
								Meteor.call \import, \pasien, selector: sel, modifier: opt
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
								Meteor.call \import, \gudang, selector: sel, modifier: opt
							if data.harga
								sel = nama: _.snakeCase data.nama
								opt =
									harga: +data.harga
									first: data.first
									second: data.second
									third: that if data.third
									active: true
								Meteor.call \import, \tarif, selector: sel, modifier: opt
							if data.password
								<[ newUser importRoles ]>map (i) ->
									Meteor.call i, data
							if data.daerah then coll.daerah.insert do
								daerah: _.lowerCase data.daerah
								provinsi: +that if data.provinsi
								kabupaten: +that if data.kabupaten
								kecamatan: +that if data.kecamatan
								kelurahan: +that if data.kelurahan
					m \span.file-cta,
						m \span.file-icon, m \i.fa.fa-upload
						m \span.file-label, 'Pilih file .csv'
				[til 2]map -> m \br
				m \h4, 'Daftar Tarif Tindakan'
				m \table.table,
					oncreate: ->
						Meteor.subscribe \coll, \tarif, onReady: -> m.redraw!
					m \thead, m \tr, attr.manajemen.headers.tarif.map (i) ->
						m \th, _.startCase i
					m \tbody, pagins(coll.tarif.find!fetch!)map (i) -> m \tr, tds arr =
						_.startCase i.nama
						rupiah i.harga
						_.startCase i.first
						_.startCase i.second
						_.startCase i.third
						if i.active then \Aktif else \Non-aktif
				elem.pagins!

		amprah: -> view: -> m \.content,
			oncreate: ->
				Meteor.subscribe \users, onReady: -> m.redraw!
				Meteor.subscribe \coll, \gudang, onReady: -> m.redraw!
				state.showForm = obat: false, bhp: false
			_.compact(attr.amprah.reqForm!)map (type) -> m \div,
				[til 1]map (i) -> m \br
				m \.button.is-primary,
					onclick: -> state?showForm[type] = not state?showForm[type]
					m \span, m \i.fa.fa-shopping-basket
					m \span, "Request #{_.upperCase type}"
				if state.showForm?[type] and !userGroup(\farmasi)
					m \h4, 'Form Amprah'
					m autoForm do
						collection: coll.amprah
						schema: new SimpleSchema schema.amprah type
						type: \insert
						id: "formAmprah#type"
						columns: 4
						hooks: after: ->
							state.showForm = obat: false, bhp: false
							m.redraw!
			m \br
			m \h4, 'Daftar Amprah'
			m \table.table,
				oncreate: ->
					Meteor.subscribe \users, onReady: -> m.redraw!
					Meteor.subscribe \coll, \amprah, onReady: -> m.redraw!
				m \thead, m \tr,
					attr.amprah.headers.requests.map (i) -> m \th, _.startCase i
				m \tbody, pagins(attr.amprah.amprahList!)map (i) -> m \tr, tds arr =
					hari i.tanggal_minta
					(?full or _.startCase i.ruangan) modules.find -> it.name is i.ruangan
					_.startCase (?username) Meteor.users.findOne i.peminta
					"#{i.jumlah} unit"
					look2(\gudang, i.nama)?nama
					if i.penyerah then _.startCase (?username) Meteor.users.findOne that
					if i.diserah then "#that unit"
					if i.tanggal_serah then hari that
					if attr.amprah.buttonConds(i)
						m \.button.is-primary,
							onclick: -> state.modal = i
							m \span, \Serah
				m \br
				elem.pagins!
			if state.modal then elem.modal do
				title: 'Respon Amprah'
				content:
					if state.modal.nama then m \div,
						m \table.table,
							m \thead, m \tr, <[nama_barang diminta sedia]>map (i) ->
								m \th, _.startCase i
							m \tbody, m \tr, tds arr =
								look2(\gudang, state.modal.nama)nama
								state.modal.jumlah
								attr.amprah.available!
						m autoForm do
							schema: new SimpleSchema schema.responAmprah
							id: \formResponAmprah
							type: \method
							meteormethod: \serahAmprah
							hooks:
								before: (doc, cb) ->
									if doc.diserah <= attr.amprah.available!
										cb _.merge doc, state.modal
								after: (doc) ->
									state.modal = doc
									m.redraw!
					else m \table.table,
						m \thead, m \tr, <[ nama_obat no_batch serahkan ]>map (i) ->
							m \th, _.startCase i
						m \tbody, state.modal.map (i) -> m \tr,
							tds [i.nama_obat, i.no_batch, i.serah]

	m.route.prefix ''
	m.route document.body, \/dashboard,
		_.merge '/dashboard': comp.layout(comp.welcome!),
			... modules.map ({name}) -> "/#name": comp.layout comp[name]?!
			'/regis/:jenis': comp.layout comp.pasien!
			'/regis/:jenis/:idpasien': comp.layout comp.pasien!
			'/jalan/:idpasien': comp.layout comp.pasien!
			'/manajemen/:subroute': comp.layout comp.manajemen!
			'/login': comp.layout comp.login!
			'/farmasi/:idbarang': comp.layout comp.farmasi!
