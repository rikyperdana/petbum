schema.regis =
	no_mr: type: Number, min: 100000, max: 999999
	regis: type: Object
	'regis.alias': type: Number, optional: true, autoform: options: selects.alias
	'regis.nama_lengkap': type: String
	'regis.no_ktp': type: Number, max: 9999999999999999, optional: true
	'regis.tgl_lahir': type: Date
	'regis.tmpt_lahir': type: String, optional: true
	'regis.kelamin': type: Number, autoform: options: selects.kelamin
	'regis.agama': type: Number, optional: true, autoform: options: selects.agama
	'regis.nikah': type: Number, optional: true, autoform: options: selects.nikah
	'regis.pendidikan': type: Number, optional: true, autoform: options: selects.pendidikan
	'regis.darah': type: Number, optional: true, autoform: options: selects.darah
	'regis.pekerjaan': type: Number, optional: true, autoform: options: selects.pekerjaan
	'regis.kabupaten': type: String, optional: true, label: 'Kabupaten/Kota'
	'regis.kecamatan': type: String, optional: true
	'regis.kelurahan': type: String, optional: true
	'regis.alamat': type: String, optional: true
	'regis.kontak': type: String, optional: true
	'regis.ayah': type: String, optional: true
	'regis.ibu': type: String, optional: true
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
	nama: type: String, autoform: options: -> if Meteor.isClient
		_.compact coll.tarif.find!fetch!map (i) ->
			if i.jenis in roles!?jalan
				value: i._id, label: _.startCase i.nama
	harga:
		type: Number
		autoform: type: \hidden
		autoValue: (name, doc) -> if Meteor.isClient
			string = "#{_.initial(name.split \.).join \.}.nama"
			sel = doc.find -> it.name is string
			if sel?value then look2 \tarif, that .harga

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
	'rawat.$.billRegis':
		type: Number
		autoform: type: \hidden
		autoValue: (name, docs) -> if Meteor.isClient
			sel = docs.find -> \cara_bayar is _.last it.name.split \.
			if sel?value is \1 then 0
			else 1
	'rawat.$.nobill':
		type: Number
		autoform: type: \hidden
		autoValue: -> +(_.toString Date.now! .substr 7, 13)
	'rawat.$.status_bayar':
		type: Boolean
		autoform: type: \hidden
		autoValue: -> false
	'rawat.$.tinggal':
		type: Number, optional: true,
		label: 'Pasien Tinggal'
		autoform: options: selects.tinggal
	'rawat.$.tanggung_jawab': type: String

schema.rawatNurse =
	'rawat.$.anamesa_perawat': type: String, autoform: type: \textarea
	'rawat.$.fisik': type: [new SimpleSchema schema.fisik], optional: true
	'rawat.$.cara_masuk': type: Number, autoform: options: selects.cara_masuk
	'rawat.$.rujukan': type: Number, autoform: options: selects.rujukan
	'rawat.$.riwayat': type: Object, optional: true
	'rawat.$.riwayat.kesehatan': type: Object, optional: true
	'rawat.$.riwayat.kesehatan.penyakit_sebelumnya': type: String, optional: true
	'rawat.$.riwayat.kesehatan.operasi': type: String, optional: true
	'rawat.$.riwayat.kesehatan.dirawat': type: String, optional: true
	'rawat.$.riwayat.kesehatan.pengobatan_dirumah': type: String, optional: true
	'rawat.$.riwayat.kesehatan.alergi': type: String, optional: true
	'rawat.$.riwayat.kesehatan.transfusi_darah': type: String, optional: true
	'rawat.$.riwayat.kesehatan.merokok': type: String, optional: true
	'rawat.$.riwayat.kesehatan.minuman_keras': type: String, optional: true
	'rawat.$.riwayat.kesehatan.obat_terlarang': type: String, optional: true
	'rawat.$.riwayat.kesehatan.imunisasi': type: String, optional: true, autoform: options: selects.imunisasi
	'rawat.$.riwayat.keluarga': type: Object, optional: true
	'rawat.$.riwayat.keluarga.penyakit': type: Number, optional: true, autoform: options:  selects.penyakit
	'rawat.$.riwayat.keluarga.hubungan': type: String, optional: true
	'rawat.$.riwayat.reproduksi': type: Object, optional: true
	'rawat.$.riwayat.reproduksi.wanita_hamil': type: Boolean, optional: true
	'rawat.$.riwayat.reproduksi.pria_prostat': type: Boolean, optional: true
	'rawat.$.riwayat.reproduksi.keikutsertaan_kb': type: Number, optional: true, autoform: options: selects.kb
	'rawat.$.kenyamanan': type: Object, optional: true
	'rawat.$.kenyamanan.nyeri': type: Boolean, optional: true
	'rawat.$.kenyamanan.lokasi': type: String, optional: true
	'rawat.$.kenyamanan.frekuensi': type: Number, optional: true, autoform: options: selects.frekuensi
	'rawat.$.kenyamanan.karakteristik_nyeri': type: Number, optional: true, autoform: options: selects.nyeri
	'rawat.$.status_psikologi': type: Number, optional: true, autoform: options: selects.psikologi
	'rawat.$.eliminasi': type: Object, optional: true
	'rawat.$.eliminasi.bab': type: Number, optional: true, autoform: options: selects.bab
	'rawat.$.eliminasi.bak': type: Number, optional: true, autoform: options: selects.bak
	'rawat.$.komunikasi': type: Object, optional: true
	'rawat.$.komunikasi.bicara': type: Number, optional: true, autoform: options: selects.bicara
	'rawat.$.komunikasi.hambatan': type: Number, optional: true, autoform: options: selects.hambatan
	'rawat.$.komunikasi.potensial': type: Number, optional: true, autoform: options: selects.potensial

schema.rawatDoctor =
	'rawat.$.anamesa_dokter': type: String, optional: true, autoform: type: \textarea
	'rawat.$.diagnosa': type: [String], optional: true
	'rawat.$.planning': type: String, optional: true, autoform: type: \textarea
	'rawat.$.tindakan': type: [new SimpleSchema schema.tindakan], optional: true
	'rawat.$.obat': type: [new SimpleSchema schema.obat], optional: true
	'rawat.$.spm':
		type: Number
		autoform: type: \hidden
		autoValue: -> moment!diff state.spm, \minutes
	'rawat.$.pindah': type: Number, optional: true, autoform: options: selects.klinik
	'rawat.$.keluar': type: Number, optional: true, autoform: options: selects.keluar

schema.rawatMR =
	'rawat.$.icdX': type: String

schema.addRole =
	roles: type: String, optional: true, autoform: type: \select, options: ->
		<[ admin petugas perawat dokter mr ]>map -> value: it, label: _.startCase it
	group: type: String, autoform: type: \select, options: ->
		modules.map -> value: it.name, label: it.full
	poli: type: String, optional: true, autoform: type: \select, options: ->
		selects.klinik.map -> label: it.label, value: _.snakeCase it.label

schema.gudang =
	idbarang:
		type: String
		autoform: type: \hidden
		autoValue: -> randomId!
	jenis: type: Number, autoform: options: selects.barang
	nama: type: String

schema.farmasi = _.assign {}, schema.gudang,
	kandungan: type: String, optional: true
	satuan: type: Number, autoform: options: selects.satuan
	batch: type: Array
	'batch.$': type: Object
	'batch.$.idbatch':
		type: String
		autoform: type: \hidden
		autoValue: -> randomId!
	'batch.$.nobatch': type: String
	'batch.$.merek': type: String
	'batch.$.masuk': type: Date
	'batch.$.kadaluarsa': type: Date
	'batch.$.digudang': type: Number
	'batch.$.diapotik': type: Number, autoValue: -> 0
	'batch.$.diretur': type: Boolean, optional: true
	'batch.$.beli': type: Number, decimal: true
	'batch.$.jual': type: Number, decimal: true
	'batch.$.suplier': type: String
	'batch.$.returnable': type: Boolean, optional: true
	'batch.$.anggaran': type: Number, autoform: options: selects.anggaran
	'batch.$.pengadaan': type: Number

<[ pasien gudang tarif rekap ]>map (i) ->
	coll[i] = new Meteor.Collection i
	coll[i]allow _.merge ... <[ insert update remove ]>map -> "#it": -> true
