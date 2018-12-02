@selects =
	rawat: <[ rawat_jalan rawat_inap igd ]>
	pekerjaan: <[ pns swasta wiraswasta tni polri pensiunan lainnya ]>
	kelamin: <[ laki_laki perempuan ]>
	agama: <[ islam katolik protestan buddha hindu kong_hu_chu ]>
	pendidikan: <[ sd smp sma diploma s1 s2 s3 tidak_sekolah ]>
	darah: <[ a b ab o ]>
	cara_bayar: <[ umum bpjs jamkesda_pekanbaru jamkesda_kampar lapas_dinsos ]>
	nikah: <[ nikah belum_nikah janda duda ]>
	klinik: <[ penyakit_dalam gigi kebidanan tht anak saraf mata bedah paru tb_dots kulit fisioterapi gizi metadon psikologi tindakan aps_labor aps_radio ]>
	karcis: [ 40 30 40 40 40 40 40 40 40 40 40 0 25 30 25 0 0 0 ]
	bentuk: <[ butir kapsul tablet sendok_makan sendok_teh ]>
	tipe_dokter: <[ umum spesialis ]>
	rujukan: <[ datang_sendiri rs_lain puskesmas faskes_lainnya ]>
	keluar: <[ pulang rujuk ]>
	barang: <[ generik non_generik obat_narkotika bhp ]>
	satuan: <[ botol vial ampul pcs sachet tube supp tablet minidose pot turbuhaler kaplet kapsul bag pen rectal flash cream nebu galon lembar roll liter cup pasang bungkus ]>
	anggaran: <[ blud apbd kemenkes dinkes ]>
	alias: <[ tn ny nn an by ]>
	tinggal: <[ orang_tua keluarga sendiri panti_asuhan ]>
	cara_masuk: <[ jalan kursi_roda lainnya ]>
	imunisasi: <[ dpt1 dpt2 dpt3 bcg campak polio1 polio2 polio3 hepatitis mmr ]>
	penyakit: <[ asma diabetes hipertensi cancer anemia jantung lainnya ]>
	kb: <[ iud susuk suntik pil steril vasectomi ]>
	frekuensi: <[ sering kadang jarang ]>
	nyeri: <[ terbakar tertindih menyebar tajam tumpul berdenyut lainnya ]>
	psikologi: <[ tenang marah cemas gelisah takut lainnya ]>
	bab: <[ asma diare konstipasi colostomy ]>
	bak: <[ normal retensia inkontinesia poliuria disuria lainnya ]>
	bicara: <[ normal gangguan_bicara lainnya ]>
	hambatan: <[ tidak_ada pendengaran cemas motivasi_memburuk bahasa lainnya ]>
	potensial: <[ proses_penyakit pengobatan nutrisi tindakan lainnya ]>

_.map selects, (i, j) -> selects[j] = _.map selects[j], (m, n) -> value: n+1, label: _.startCase m

selects.tindakan = -> if Meteor.isClient
	coll.tarif?find!fetch!map ->
		value: it._id, label: it.nama

selects.gudang = -> if Meteor.isClient
	coll.gudang.find!fetch!map (i) ->
		value: i._id, label: i.nama

selects.obat = -> if Meteor.isClient
	_.compact coll.gudang.find!fetch!map (i) ->
		if i.jenis in [1 2 3] then value: i._id, label: i.nama

selects.bhp = -> if Meteor.isClient
	_.compact coll.gudang.find!fetch!map (i) ->
		if i.jenis is 4 then value: i._id, label: i.nama
