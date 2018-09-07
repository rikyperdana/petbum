schema.regis =
	no_mr: type: Number, max: 999999
	regis: type: Object
	'regis.alias': type: Number, optional: true, autoform: options: selects.alias
	'regis.nama_lengkap': type: String
	'regis.tgl_lahir': type: Date
	'regis.tmpt_lahir': type: String, optional: true
	'regis.kelamin': type: Number, autoform: options: selects.kelamin
	'regis.agama': type: Number, optional: true, autoform: options: selects.agama
	'regis.nikah': type: Number, optional: true, autoform: options: selects.nikah
	'regis.pendidikan': type: Number, optional: true, autoform: options: selects.pendidikan
	'regis.darah': type: Number, optional: true, autoform: options: selects.darah
	'regis.pekerjaan': type: Number, optional: true, autoform: options: selects.pekerjaan
	'regis.kabupaten': type: String, optional: true
	'regis.kecamatan': type: String, optional: true
	'regis.kelurahan': type: String, optional: true
	'regis.alamat': type: String, optional: true
	'regis.kontak': type: String, optional: true
	'regis.ayah': type: String, optional: true
	'regis.ibu': type: String, optional: true
	'regis.pasangan': type: String, optional: true
	'regis.tanggal':
		type: Date
		autoform: type: \hidden
		autoValue: -> new Date!

schema.fisik =
	tekanan_darah: type: String, optional: true
	nadi: type: Number, optional: true
	suhu: type: Number, decimal: true, optional: true
	pernapasan: type: Number, optional: true
	berat: type: Number, optional: true
	tinggi: type: Number, optional: true
	lila: type: Number, optional: true

schema.tindakan =
	idtindakan:
		type: String
		autoform: type: \hidden
		autoValue: -> randomId!
	nama: type: String, autoform: options: selects.tindakan
	dokter: type: String, autoform: options: null

schema.obat =
	idobat:
		type: String
		autoform: type: \hidden
		autoValue: -> randomId!
	nama: type: String, autoform: options: selects.obat
	puyer: type: String, optional: true
	aturan: type: Object
	'aturan.kali': type: Number
	'aturan.dosis': type: Number
	'aturan.bentuk': type: Number, autoform: type: \hidden
	jumlah: type: Number
	harga:
		type: Number
		autoform: type: \hidden
		autoValue: -> null
	subtotal:
		type: Number
		autoform: type: \hidden
		autoValue: -> null
	hasil: type: String, optional: true, autoform: type: \hidden

schema.rawatRegis =
	no_mr: type: Number
	rawat: type: Array
	'rawat.$': type: Object
	'rawat.$.idrawat':
		type: String
		autoform: type: \hidden
		autoValue: -> randomId!
	'rawat.$.tanggal':
		type: Date
		autoform: type: \hidden
		autoValue: -> new Date!
	'rawat.$.cara_bayar': type: Number, autoform: options: selects.cara_bayar
	'rawat.$.klinik': type: Number, autoform: options: selects.klinik
	'rawat.$.karcis':
		type: Number
		autoform: type: \hidden
		autoValue: (name, doc) -> 30000
	'rawat.$.rujukan': type: Number, autoform: options: selects.rujukan
	'rawat.$.billRegis':
		type: Boolean
		autoform: type: \hidden
		autoValue: -> false
	'rawat.$.nobill':
		type: Number
		autoform: type: \hidden
		autoValue: -> +(_.toString Date.now! .substr 7, 13)
	'rawat.$.status_bayar':
		type: Boolean
		autoform: type: \hidden
		autoValue: -> false

schema.rawatNurse =
	'rawat.$.anamesa_perawat': type: String, autoform: type: \textarea
	'rawat.$.fisik': type: [new SimpleSchema schema.fisik]

schema.rawatDoctor =
	'rawat.$.anamesa_dokter': type: String, optional: true, autoform: type: \textarea
	'rawat.$.diagnosa': type: String, optional: true, autoform: type: \textarea
	'rawat.$.planning': type: String, optional: true, autoform: type: \textarea
	'rawat.$.tindakan': type: [new SimpleSchema schema.tindakan], optional: true
	'rawat.$.obat': type: [new SimpleSchema schema.obat], optional: true
	'rawat.$.total': type: Object, autoform: type: \hidden
	'rawat.$.total.tindakan':
		type: Number, optional: true,
		autoform: type: \hidden
		autoValue: -> null
	'rawat.$.total.obat':
		type: Number, optional: true,
		autoform: type: \hidden
		autoValue: -> nul
	'rawat.$.spm':
		type: Number
		autoform: type: \hidden
		autoValue: -> null
	'rawat.$.pindah': type: Number, optional: true, autoform: options: selects.klinik
	'rawat.$.keluar': type: Number, optional: true, autoform: options: selects.keluar

schema.addRole =
	roles: type: String, optional: true, autoform: type: \select, options: ->
		<[ admin petugas ]>map -> value: it, label: _.startCase it
	group: type: String, autoform: type: \select, options: ->
		modules.map -> value: it.name, label: _.startCase it.name
	poli: type: String, optional: true, autoform: type: \select, options: ->
		selects.klinik.map -> label: it.label, value: _.snakeCase it.label

<[ pasien gudang tarif ]>map (i) ->
	coll[i] = new Meteor.Collection i
	coll[i]allow _.merge ... <[ insert update ]>map -> "#it": -> true
