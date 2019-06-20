@selects =
	rawat: <[ rawat_jalan rawat_inap igd ]>
	pekerjaan: <[ pns swasta wiraswasta tni polri pensiunan lainnya ]>
	kelamin: <[ laki_laki perempuan ]>
	agama: <[ islam katolik protestan buddha hindu kong_hu_chu ]>
	pendidikan: <[ sd smp sma diploma s1 s2 s3 tidak_sekolah ]>
	darah: <[ a b ab o ]>
	cara_bayar: <[ umum bpjs jamkesda_pekanbaru jamkesda_kampar lapas_dinsos jampersal ]>
	nikah: <[ nikah belum_nikah janda duda ]>
	klinik: <[ penyakit_dalam gigi kebidanan tht anak saraf mata bedah paru kulit fisioterapi gizi psikologi tindakan aps_labor aps_radio ]>
	karcis: [  50             30   50        50  50   50    50   50    50   50    50          50   50        50       0         0 ]
	bentuk: <[ butir kapsul tablet sendok_makan sendok_teh ]>
	tipe_dokter: <[ umum spesialis ]>
	rujukan: <[ datang_sendiri rs_lain puskesmas faskes_lainnya ]>
	keluar: <[ pulang rujuk inap ]>
	barang: <[ generik non_generik obat_narkotika bhp obat_keras_tertentu]>
	satuan: <[ botol vial ampul pcs sachet tube supp tablet minidose pot turbuhaler kaplet kapsul bag pen rectal flash cream nebu galon lembar roll liter cup pasang bungkus box syringe]>
	anggaran: <[ blud apbd ]>
	alias: <[ tn ny nn an by ]>
	tinggal: <[ orang_tua keluarga sendiri panti_asuhan ]>
	cara_masuk: <[ jalan kursi_roda lainnya ]>
	imunisasi: <[ dpt1 dpt2 dpt3 bcg campak polio1 polio2 polio3 hepatitis mmr ]>
	penyakit: <[ asma diabetes hipertensi cancer anemia jantung lainnya ]>
	kb: <[ iud susuk suntik pil steril vasectomi ]>
	nyeri: <[ya tidak]>
	frekuensi: <[ sering kadang jarang ]>
	karakteristik_nyeri: <[ terbakar tertindih menyebar tajam tumpul berdenyut lainnya ]>
	psikologi: <[ tenang marah cemas gelisah takut lainnya ]>
	bab: <[ asma diare konstipasi colostomy ]>
	bak: <[ normal retensia inkontinesia poliuria disuria lainnya ]>
	bicara: <[ normal gangguan_bicara lainnya ]>
	hambatan: <[ tidak_ada pendengaran cemas motivasi_memburuk bahasa lainnya ]>
	potensial: <[ proses_penyakit pengobatan nutrisi tindakan lainnya ]>
	yatidak: <[ ya tidak ]>

_.map selects, (i, j) -> selects[j] = _.map selects[j], (m, n) -> value: n+1, label: _.startCase m

selects.tindakan = -> if Meteor.isClient
	coll.tarif?find!fetch!map ->
		value: it._id, label: it.nama

selects.grupTindakan = -> if Meteor.isClient
	a = coll.tarif?find!fetch!filter -> ands arr =
		it.first is \jalan
		it.second is _.snakeCase (.label) selects.klinik.find ->
			it.value is (.klinik) coll.pasien.findOne(m.route.param \idpasien)rawat.find ->
				it.idrawat is state.docRawat
	(_.uniqBy a, \third)map ->
		value: it.third
		label: _.startCase it.third

selects.namaTindakan = (name) -> if Meteor.isClient
	current = "#{_.initial name.split(\.) .join \.}.grup"
	a = coll.tarif?find!fetch!filter -> ands arr =
		it.first is \jalan
		it.second is _.snakeCase (.label) selects.klinik.find ->
			it.value is (.klinik) coll.pasien.findOne(m.route.param \idpasien)rawat.find ->
				it.idrawat is state.docRawat
		it.third is afState.form.formRawat[current]
	a.map -> value: it._id, label: _.startCase it.nama

selects.gudang = -> if Meteor.isClient
	coll.gudang.find!fetch!map (i) ->
		value: i._id, label: i.nama

[{name: \obat, jenis: [1 2 3]}, {name: \bhp, jenis: [4]}]map (i) ->
	selects[i.name] = (name) -> if Meteor.isClient
		term =
			if (_.includes name, "#{i.name}.")
				"#{_.initial name.split(\.) .join \.}.search"
			else if name is \nama then \search
		list = <[formRawat formSerahObat formAmprahobat formAmprahbhp]>
		form = if afState.form then ors list.map -> that[it]
		a = coll.gudang.find!fetch!filter (j) -> ands arr =
			j.jenis in i.jenis
			_.includes _.lowerCase(j.nama), form[term]
		a.map -> value: it._id, label: it.nama

selects.dokter = -> if Meteor.isClient
	selPoli = afState.form.formJalan[\rawat.1.klinik] - 1
	a = Meteor.users.find!fetch!filter (i) -> ands arr =
		_.split i.username, \. .0 in <[ dr drg ]>
		_.includes i.roles?jalan, (.[selPoli]) selects.klinik.map -> _.snakeCase it.label
	a.map -> value: it._id, label: _.startCase it.username

selects.provinsi = -> if Meteor.isClient
	coll.daerah.find!fetch!filter -> it.provinsi and not it.kabupaten
	.map -> value: it.provinsi, label: _.startCase it.daerah

selects.kabupaten = -> if Meteor.isClient
	if +afState.form.formRegis[\regis.provinsi]
		coll.daerah.find!fetch!filter -> it.provinsi is that and it.kabupaten
		.map -> value: it.kabupaten, label: _.startCase it.daerah

selects.kecamatan = -> if Meteor.isClient
	if +afState.form.formRegis[\regis.kabupaten]
		coll.daerah.find!fetch!filter -> it.kabupaten is that and it.kecamatan
		.map -> value: it.kecamatan, label: _.startCase it.daerah

selects.kelurahan = -> if Meteor.isClient
	if +afState.form.formRegis[\regis.kecamatan]
		coll.daerah.find!fetch!filter -> it.kecamatan is that and it.kelurahan
		.map -> value: it.kelurahan, label: _.startCase it.daerah
