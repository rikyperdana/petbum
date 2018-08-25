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
	'regis.tgl_daftar':
		type: Date
		autoform: type: \hidden
		autoValue: -> new Date!

coll.pasien = new Meteor.Collection \pasien
coll.pasien.allow insert: -> true
