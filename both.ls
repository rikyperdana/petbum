<[ pasien gudang tarif rekap amprah daerah]>map (i) ->
	coll[i] = new Meteor.Collection i
	coll[i]allow _.merge ... <[ insert update remove ]>map -> "#it": -> true
	if Meteor.isClient then <[added changed]>map (j) ->
		coll[i]find!observe "#j": -> m.redraw!

if Meteor.isClient
	schema.regis =
		no_mr: type: Number, min: 100000, max: 999999
		regis: type: Object
		'regis.alias': type: Number, optional: true, autoform: options: selects.alias
		'regis.nama_lengkap': type: String
		'regis.no_ktp': type: Number, max: 9999999999999999, optional: true
		'regis.tgl_lahir': type: Date
		'regis.tmpt_lahir': type: String, optional: true
		'regis.kelamin': type: Number, optional: true, autoform: options: selects.kelamin
		'regis.agama': type: Number, optional: true, autoform: options: selects.agama
		'regis.nikah': type: Number, optional: true, label: 'Status Nikah', autoform: options: selects.nikah
		'regis.pendidikan': type: Number, optional: true, label: 'Pendidikan Terakhir', autoform: options: selects.pendidikan
		'regis.darah': type: Number, optional: true, label: 'Golongan Darah', autoform: options: selects.darah
		'regis.pekerjaan': type: Number, optional: true, autoform: options: selects.pekerjaan
		'regis.alamat': type: String, optional: true
		'regis.provinsi': type: Number, optional: true, autoform: options: selects.provinsi
		'regis.kabupaten': type: Number, optional: true, label: 'Kabupaten/Kota', autoform: options: selects.kabupaten
		'regis.kecamatan': type: Number, optional: true, autoform: options: selects.kecamatan
		'regis.kelurahan': type: Number, optional: true, autoform: options: selects.kelurahan
		'regis.kontak': type: String, optional: true
		'regis.ayah': type: String, optional: true
		'regis.ibu': type: String, optional: true
		'regis.pasangan': type: String, optional: true, label: 'Suami/Istri'
		'regis.tanggal':
			type: Date
			autoform: type: \hidden
			autoValue: -> new Date!

	schema.fisik =
		tekanan_darah: type: String, optional: true
		nadi: type: Number, optional: true, decimal: true
		suhu: type: Number, optional: true, decimal: true
		pernapasan: type: Number, optional: true, decimal: true
		berat: type: Number, optional: true, decimal: true
		tinggi: type: Number, optional: true, decimal: true
		lila: type: Number, optional: true, decimal: true

	schema.tindakan =
		idtindakan:
			type: String
			autoform: type: \hidden
			autoValue: -> randomId!
		grup: type: String, autoform: options: selects.grupTindakan
		nama: type: String, autoform: options: selects.namaTindakan
		harga:
			type: Number
			autoform: type: \hidden
			autoValue: (name, doc) ->
				string = "#{_.initial(name.split \.)join \.}.nama"
				sel = doc.find -> it.name is string
				if sel?value then look2 \tarif, that .harga

	schema.obat =
		idobat:
			type: String
			autoform: type: \hidden
			autoValue: -> randomId!
		nama: type: String, label: 'Nama Obat', autoform: options: selects.obat
		puyer: type: String, optional: true
		aturan: type: Object
		'aturan.kali': type: Number, label: 'Kali sehari'
		'aturan.dosis': type: String
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
		'rawat.$.klinik': type: Number, label: 'Poliklinik', autoform: options: selects.klinik
		'rawat.$.dokter': type: String, optional: true, autoform: options: selects.dokter
		'rawat.$.billRegis':
			type: Number
			autoform: type: \hidden
			autoValue: (name, docs) ->
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
		'rawat.$.tanggung_jawab': type: String, optional: true

	schema.rawatNurse =
		'rawat.$.anamesa_perawat': type: String, autoform: type: \textarea
		'rawat.$.fisik': optional: true, type: new SimpleSchema schema.fisik
		'rawat.$.cara_masuk': type: Number, optional: true, autoform: options: selects.cara_masuk, firstLabel: 'Pilih Satu'
		'rawat.$.rujukan': type: Number, optional: true, autoform: options: selects.rujukan
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
		'rawat.$.anamesa_dokter': type: String, autoform: type: \textarea
		'rawat.$.diagnosa': type: [String]
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
		'batch.$.merek': type: String, optional: true
		'batch.$.masuk': type: Date
		'batch.$.kadaluarsa': type: Date
		'batch.$.digudang': type: Number
		'batch.$.awal':
			type: Number
			autoform: type: \hidden
			autoValue: (name, docs) ->
				(?value) docs.find ->
					\digudang is _.last it.name.split \.
		'batch.$.diapotik':
			type: Number
			autoform: type: \hidden
			autoValue: -> 0
		'batch.$.diretur': type: Boolean, optional: true, autoform: type: \hidden
		'batch.$.beli': type: Number, decimal: true
		'batch.$.jual': type: Number, decimal: true, optional: true
		'batch.$.suplier': type: String, optional: true
		'batch.$.returnable': type: Number, optional: true, autoform: options: selects.returnable
		'batch.$.anggaran': type: Number, optional: true, autoform: options: selects.anggaran
		'batch.$.pengadaan': type: Number, optional: true

	schema.amprah = (type) ->
		nama: type: String, autoform: type: \select, options: selects[type]
		jumlah: type: Number
		tanggal_minta:
			type: Date
			autoform: type: \hidden
			autoValue: -> new Date!
		peminta:
			type: String
			autoform: type: \hidden
			autoValue: -> Meteor.userId!
		ruangan:
			type: String
			autoform: type: \hidden
			autoValue: -> userGroup!

	schema.responAmprah =
		diserah: type: Number
		penyerah:
			type: String
			autoform: type: \hidden
			autoValue: -> Meteor.userId!
		tanggal_serah:
			type: Date
			autoform: type: \hidden
			autoValue: -> new Date!
