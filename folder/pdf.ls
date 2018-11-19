if Meteor.isClient

	@makePdf =
		card: ->
			doc = coll.pasien.findOne!
			pdf = pdfMake.createPdf do
				content:
					"Nama : #{doc.regis.nama_lengkap}"
					"No. MR: #{zeros doc.no_mr}"
				pageSize: \B8
				pageMargins: [110 50 0 0]
				pageOrientation: \landscape
			pdf.download "#{zeros doc.no_mr}_card.pdf"

		consent: ->
			doc = coll.pasien.findOne!
			pdf = pdfMake.createPdf do
				content: [
					{text: 'PEMERINTAH PROVINSI RIAU\nRUMAH SAKIT UMUM DAERAH PETALA BUMI\nJL. Dr. Soetomo No. 65, Telp. (0761) 23024', alignment: 'center'}
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
				]
			pdf.download "#{zeros doc.no_mr}_consent.pdf"

		payRawat: (idpasien, idrawat, rows) ->
			pasien = coll.pasien.findOne idpasien
			rawat = pasien.rawat.find -> it.idrawat is idrawat
			items = rows.map -> [it.0, rupiah it.1]
			table = table: widths: [\*, \auto], body: [[\Uraian \Harga], ...items]
			pdf = pdfMake.createPdf do
				content: [
					{text: 'PEMERINTAH PROVINSI RIAU\nRUMAH SAKIT UMUM DAERAH PETALA BUMI\nJL. DR. SOETOMO NO. 65, TELP. (0761) 23024, PEKANBARU', alignment: 'center'}
					{text: '\nRINCIAN BIAYA RAWAT JALAN\n', alignment: 'center'}
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
				]
			pdf.download "#{zeros pasien.no_mr}_payRawat.pdf"

		payRegCard: (idpasien, idrawat, rows) ->
			doc = coll.pasien.findOne idpasien
			pdf = pdfMake.createPdf do
				content: [
					{text: 'PEMERINTAH PROVINSI RIAU\nRUMAH SAKIT UMUM DAERAH PETALA BUMI\nJL. DR. SOETOMO NO. 65, TELP. (0761) 23024, PEKANBARU', alignment: 'center'}
					{text: '\n\nKARCIS', alignment: \center}
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
				]
			pdf.download "#{zeros doc.no_mr}_payRegCard.pdf"

		rekap: ->
			fields = <[ no_mr nama_pasien nama_obat nobatch jumlah ]>
			rows = _.flatten coll.rekap.find!fetch!map (i) ->
				i.batches.map (i) -> fields.map -> i[it]toString!
			headers = [fields.map -> _.startCase it]
			if rows.length > 0
				pdfMake.createPdf content:
					[table: body: [...headers, ...rows]]
				.download \cetak_rekap.pdf
				Meteor.call \doneRekap

		icdx: (pasien) ->
			headers = <[tanggal klinik dokter diagnosa terapi perawat icd10]>
			rows = _.compact _.flatten pasien.rawat.map (i) -> i.icdx?map (j, k) -> arr =
				hari i.tanggal
				look(\klinik, i.klinik)label
				Meteor.users.findOne(i.petugas.dokter)username
				i.diagnosa[k]
				\-
				Meteor.users.findOne(i.petugas.perawat)username
				i.icdx[k]
			columns = arr =
				['NO. MR', 'NAMA LENGKAP', 'TANGGAL LAHIR', 'JENIS KELAMIN']
				arr =
					pasien.no_mr.toString!
					pasien.regis.nama_lengkap
					hari pasien.regis.tgl_lahir
					look(\kelamin, pasien.regis.kelamin)label
			pdfMake.createPdf content: arr =
				{text: 'FORM RESUME RAWAT JALAN', alignment: \center}
				'\n\n'
				{columns: columns}
				'\n\n'
				{table: body: [headers.map(-> _.startCase it), ...rows]}
			.download "icdX_#{pasien.no_mr}.pdf"
