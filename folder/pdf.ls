if Meteor.isClient

	kop = {text: 'PEMERINTAH PROVINSI RIAU\nRUMAH SAKIT UMUM DAERAH PETALA BUMI\nJL. Dr. Soetomo No. 65, Telp. (0761) 23024\n\n\n', alignment: \center, bold: true}

	@makePdf =
		card: (idpasien) ->
			doc = coll.pasien.findOne idpasien
			pdf = pdfMake.createPdf do
				content:
					"Nama : #{doc.regis.nama_lengkap}"
					"No. MR: #{zeros doc.no_mr}"
				pageSize: \B8
				pageMargins: [110 50 0 0]
				pageOrientation: \landscape
			pdf.download "#{zeros doc.no_mr}_card.pdf"

		consent: ->
			doc = coll.pasien.findOne m.route.param \idpasien
			pdf = pdfMake.createPdf content: arr =
				kop
				{text: '\nDATA UMUM PASIEN', alignment: \center}
				{columns: [
					['NO. MR', 'NAMA LENGKAP', 'TEMPAT & TANGGAL LAHIR', 'GOLONGAN DARAH', 'JENIS KELAMIN', 'AGAMA', 'PENDIDIKAN', 'PEKERJAAN', 'NAMA AYAH', 'NAMA IBU', 'NAMA SUAMI / ISTRI', 'ALAMAT', 'NO. TELP / HP']
					[
						zeros doc.no_mr
						doc.regis.nama_lengkap
						"#{doc.regis.tmpt_lahir or \-}, #{moment doc.regis.tgl_lahir .format 'D/MM/YYYY'}"
						... _.map <[ darah kelamin agama pendidikan pekerjaan ]>, (i) ->
							look(i, doc.regis[i])?label or \-
						... _.map <[ ayah ibu pasangan alamat kontak ]>, (i) ->
							doc.regis[i] or \-
					]map -> ": #it"
				]}
				{text: '\nPERSETUJUAN UMUM (GENERAL CONSENT)', alignment: \center}
				{table: body: [
					[\S, \TS, {text: \Keterangan, alignment: \center}]
					... [
						['Saya akan mentaati peraturan yang berlaku di RSUD Petala Bumi']
						['Saya memberi kuasa kepada dokter dan semua tenaga kesehatan untuk melakukan pemeriksaan / pengobatan / tindakan yang diperlakukan upaya kesembuhan saya / pasien tersebut diatas']
						['Saya memberi kuasa kepada dokter dan semua tenaga kesehatan yang ikut merawat saya untuk memberikan keterangan medis saya kepada yang bertanggung jawab atas biaya perawatan saya.']
						['Saya memberi kuasa kepada RSUD Petala Bumi untuk menginformasikan identitas sosial saya kepada keluarga / rekan / masyarakat']
						['Saya mengatakan bahwa informasi hasil pemeriksaan / rekam medis saya dapat digunakan untuk pendidikan / penelitian demi kemajuan ilmu kesehatan']
					]map -> [' ', ' ', ...it]
				]}
				'\nPetunjuk :'
				'S: Setuju'
				'TS: Tidak Setuju'
				{alignment: \justify, columns: [
					{text: '\n\n\n\n__________________\n'+(_.startCase Meteor.user().username), alignment: \center}
					{text: 'Pekanbaru, '+moment!format('DD/MM/YYYY')+'\n\n\n\n__________________\n'+(_.startCase doc.regis.nama_lengkap), alignment: \center}
				]}
			pdf.download "#{zeros doc.no_mr}_consent.pdf"

		payRawat: (idpasien, idrawat, rows) ->
			pasien = coll.pasien.findOne idpasien
			rawat = pasien.rawat.find -> it.idrawat is idrawat
			items = rows.map -> [it.0, rupiah it.1]
			table = table: widths: [\*, \auto], body: [[\Uraian \Harga], ...items]
			pdf = pdfMake.createPdf content: arr =
				kop
				"\n"
				{columns: [
					['NO. MR', 'NAMA PASIEN', 'JENIS KELAMIN', 'TANGGAL LAHIR', 'UMUR', 'KLINIK']
					[
						zeros pasien.no_mr
						_.startCase pasien.regis.nama_lengkap
						look(\kelamin, pasien.regis.kelamin)?label or \-
						moment!format 'D/MM/YYYY'
						"#{moment!diff pasien.regis.tgl_lahir, \years} tahun"
						look(\klinik, rawat.klinik)?label or \-
					]map -> ": #it"
				]}
				{text: '\n\nRINCIAN PEMBAYARAN', alignment: \center}
				table
				"\nTOTAL BIAYA #{rupiah _.sum rows.map -> it.1}"
				{text: '\nPEKANBARU, ' + moment!format('D/MM/YYYY') +
				'\n\n\n\n\n' + (_.startCase Meteor.user!username), alignment: \right}
			pdf.download "#{zeros pasien.no_mr}_payRawat.pdf"

		payRegCard: (idpasien, idrawat, rows) ->
			doc = coll.pasien.findOne idpasien
			pdf = pdfMake.createPdf content: arr =
				kop
				{columns: [
					['TANGGAL', 'NO. MR', 'NAMA PASIEN', 'TARIF', '\n\nPETUGAS']
					[
						moment!format 'DD/MM/YYYY'
						zeros doc.no_mr
						_.startCase doc.regis.nama_lengkap
						...rows.map -> "#{it.0} #{rupiah it.1}"
						"Total: #{rupiah _.sum rows.map -> it.1}"
						"\n\n #{_.startCase Meteor.user!username}"
					]map -> ": #it"
				]}
			pdf.download "#{zeros doc.no_mr}_payRegCard.pdf"

		rekap: ->
			fields = <[ no_mr_nama_pasien nama_obat nobatch jumlah satuan harga]>
			source = coll.rekap.find!fetch!map (i) ->
				i.obat.map (j) -> j.batches.map (k) -> arr =
					{
						text:
							if i.idpasien then "
								#{coll.pasien.findOne(i.idpasien)no_mr.toString!}
								\n#{coll.pasien.findOne(i.idpasien).regis.nama_lengkap}
							" else "#{i.no_mr}\n#{i.nama_pasien}"
						rowSpan: _.sum i.obat.map -> it.batches.length
					}
					{
						text: look2(\gudang, j.nama_obat)nama
						rowSpan: j.batches.length
					}
					k.nobatch
					k.jumlah.toString!
					do ->
						obat = coll.gudang.findOne j.nama_obat
						look \satuan, obat.satuan .label
					rupiah k.jumlah * do ->
						obat = coll.gudang.findOne j.nama_obat
						batch = obat.batch.find (i) -> i.nobatch is k.nobatch
						batch.jual
			rows = _.flattenDepth source, 2
			headers = [fields.map -> _.startCase it]
			if rows.length > 0
				Meteor.call \doneRekap
				pdfMake.createPdf content:
					[table: body: [...headers, ...rows]]
				.download \cetak_rekap.pdf

		icdx: (pasien) ->
			headers = <[tanggal klinik dokter diagnosa terapi perawat icd10]>
			rows = _.compact pasien.rawat.map (i) -> if i.tindakan then arr =
				hari i.tanggal
				look(\klinik, i.klinik)label
				_.startCase Meteor.users.findOne(i.petugas.dokter)username
				{ol: i.diagnosa}
				{ul: i.tindakan.map (j) ->
					_.startCase look2(\tarif, j.nama)nama}
				_.startCase Meteor.users.findOne(i.petugas.perawat)username
				{ol: i.icdx}
			columns =
				['NO. MR', 'NAMA LENGKAP', 'TANGGAL LAHIR', 'JENIS KELAMIN']
				arr =
					pasien.no_mr.toString!
					pasien.regis.nama_lengkap
					hari pasien.regis.tgl_lahir
					look(\kelamin, pasien.regis.kelamin)label
			console.log rows, columns
			pdfMake.createPdf content: arr =
				kop
				{text: 'FORM RESUME RAWAT JALAN', alignment: \center}
				'\n\n'
				{columns: columns}
				'\n\n'
				{table: body: [headers.map(-> _.startCase it), ...rows]}
			.download "icdX_#{pasien.no_mr}.pdf"

		csv: (name, docs) ->
			rows = docs.map -> _.map it, -> it.toString!
			headers = [_.map docs.0, (val, key) ->
				text: key, bold: true, alignment: \center]
			if rows.length > 0
				pdfMake.createPdf do
					pageOrientation: \landscape
					content: arr =
						kop
						{text: name, alignment: \center}
						'\n'
						table:
							widths: [til headers.0.length]map -> \auto
							body: [...headers, ...rows]
				.download "#name.pdf"

		ebiling: (doc) ->
			pasien = coll.pasien.findOne doc.idpasien
			rawat = _.last that.rawat if pasien
			dokter = Meteor.users.findOne(rawat.dokter)username
			title = "Billing Obat - #{pasien.no_mr or doc.no_mr} - #{pasien.regis.nama_lengkap or doc.nama_pasien} - #{hari new Date!}.pdf"
			profile = layout: \noBorders, table:
				widths: [til 4]map -> \*
				body: x =
					['Nama Lengkap', ": #{pasien.regis.nama_lengkap or doc.nama_pasien}", 'No. MR', ": #{pasien.no_mr or doc.no_mr}"]
					['Cara Bayar', ": #{look \cara_bayar, (rawat.cara_bayar or doc.cara_bayar) .label}", \Tanggal, ": #{hari new Date!}"]
					[\Poliklinik, ": #{look(\klinik, (rawat.klinik or doc.poli))label}", \Dokter, ": #{dokter or doc.dokter}"]
					['No. SEP', ": #{if doc.no_sep then that else \-}", 'Jenis Pasien', ": #{look \rawat, (doc.rawat or 1) .label}"]
			list = doc.obat.map (i) ->
				barang = look2 \gudang, i.nama_obat
				harga = barang.batch.0.jual
				satuan = look \satuan, barang.satuan .label
				jumlah = _.sumBy i.batches, \jumlah
				[(look2 \gudang, i.nama_obat .nama), jumlah, harga, jumlah * harga, satuan]
			obats = table:
				widths: [til 4]map -> \*
				body: x =
					['Nama Obat', \Jumlah, \Harga, \Total]map -> text: it, bold: true
					... list.map (i) -> [i.0, "#{i.1} #{i.4}", (rupiah i.2), (rupiah i.3)]
					['', '', {text: \Total, bold: true}, rupiah _.sum list.map -> it.3]
			petugas =
				{text: '\nPEKANBARU, ' + moment!format('D/MM/YYYY') +
				'\n\n\n\n\n' + (_.startCase Meteor.user!username), alignment: \right}
			pdfMake.createPdf do
				pageOrientation: \landscape,
				content: [kop, profile, '\n', obats, petugas], pageSize: \A5
			.download title
