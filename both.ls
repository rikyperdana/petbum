schema.regis = new SimpleSchema do
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

schema.rawat = new SimpleSchema do
	no_mr: type: Number
	rawat: type: Array
	'rawat.$': type: Object
	'rawat.$.tanggal':
		type: Date
		autoform: type: \hidden
		autoValue: -> new Date!
	'rawat.$.cara_bayar': type: Number, autoform: options: selects.cara_bayar
	'rawat.$.karcis':
		type: Number
		autoform: type: \hidden
		autoValue: (name, doc) -> 30000

coll.pasien = new Meteor.Collection \pasien
coll.pasien.allow _.merge ... <[ insert update ]>map -> "#it": -> true
