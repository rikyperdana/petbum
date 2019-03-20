if Meteor.isClient

	@guide = (group, role) ->
		if group is \regis then m \div,
			m \p, 'Untuk setiap pasien yang datang, mohon gunakan menu "Cari Pasien" terlebih dahulu untuk memastikan keberadaannya di dalam sistem.'
			m \h5, 'Menu Cari Pasien'
			ols arr =
				'Klik pada field pencarian'
				'Ketikkan pencarian berdasarkan nama atau NoMR'
				'Tekan tombol Enter pada Keyboard untuk mulai mencari'
				'Untuk mengulangi pencarian, kosongkan field dan ulangi langkah 2'
				'Bila hasil pencarian telah muncul, klik ganda pada salah satu nama'
			m \h5, 'Menu Pasien Baru'
			ols arr =
				'Jika bisa dipastikan bahwa pasien belum pernah terdaftar pada sistem, klik menu "Pasien Baru"'
				'Silahkan isikan informasi pasien. Semakin lengkap semakin baik.'
				'Bila NoMR yang diisikan telah terpakai, silahkan coba kembali dengan angka yg lain'
				'Bila sudah yakin data yang diisikan benar, klik tombol "Simpan"'
				'Anda akan langsung diarahkan ke halaman rincian pasien tersebut'
			m \h5, 'Menu Rincian Pasien'
			m \p, 'Pada menu ini Anda dapat melakukan berbagai aktifitas seperti cetak kartu, General Consent, Edit data pasien, dan menambahkan request berobat'
			ols arr =
				'Klik pada tombol "+Rawat Jalan"'
				'Isikan pilihan cara bayar, apakah umum atau asuransi'
				'Isikan pilihan poli spesialis yang dituju pasien'
				'Isikan pilihan dokter yang diinginkan, bila perlu'
				'Isikan informasi lainnya dan klik tombol "Simpan"'
				'Bila pasien memilih cara bayar umum, arahkan ke kasir. Bila jaminan, arahkan langsung ke Poli'
		else if group is \bayar then m \div,
			m \h5, 'Daftar Pembayaran'
			m \p, 'Pada halaman ini Anda dapat melihat daftar pasien yang sedang mengantri untuk membayar tagihan, baik untuk registrasi atau pembayaran tindakan'
			ols arr =
				'Klik tombol "Bayar" pada salah satu baris'
				'Anda akan melihat rincian tagihan yang harus dibayarkan pasien'
				'Bila dana telah diterima, klik tombol "Sudah"'
				'Sebuah file pdf bill pembayaran siap untuk diunduh dan dicetak'
		else if group is \jalan then m \div,
			m \h5, 'Menu Rawat Jalan bagi Perawat'
			m \p, "Pada menu ini seorang perawat dapat melihat daftar pasien yang sedang mengantri untuk dilayani di dalam Poli #{_.startCase userRole!}"
			ols arr =
				'Klik ganda pada salah satu baris nama pasien yang ingin dilayani'
				'Di bagian bawah terdapat daftar riwayat berobat, klik tombol "Lihat" pada baris teratas'
				'Sebuah Modal akan muncul, dan pastikan tanggal yang tertera adalah tanggal hari ini'
				'Klik tombol "Lanjutkan" untuk mulai mengisikan SOAP'
				'Isikan informasi yang diperlukan sesuai kebutuhan dan SOAP seorang perawat'
				'Bila sudah yakin informasi yang diisikan adalah benar, klik tombol "Simpan"'
				'Anda akan dikembalikan ke halaman rincian pasien tersebut'
				'Anda dapat meninjau kembali inputan sebelumnya dengan klik tombol "Lihat" pada baris teratas'
				'Anda dapat kembali ke halaman utama dengan klik menu "Rawat Jalan"'
			m \p, "Pada daftar yang di bawah, Anda dapat melihat daftar pasien yang telah di anamesa dan sedang menunggu dokter"
			m \h5, 'Menu Rawat Jalan bagi Dokter'
			ols arr =
				'Dapat lakukan langkah yang sama dengan perawat mulai dari 1 hingga 4'
				'Silahkan isikan informasi yang dibutuhkan sesuai dengan SOAP seorang dokter'
				'Kolom diagnosa dapat ditambahkan/dikurangi sesuai dengan jumlah diagnosa'
				'Tindakan dapat diisikan dengan memilih dari Grup dan Nama tindakan. Bisa lebih dari 1'
				'Resep obat dapat diisikan dengan memilih nama obat, aturan pakai, dan jumlah unit obat yang harus dikonsumsi'
				'Dokter bisa meresepkan beberapa obat yang berbeda dengan klik tombol "+Add" atau "-Rem"'
				'Bila dokter tersebut berupa Puyer, maka isikan informasi yang sama pada obat yang berbeda tersebut'
				'Isikan pilihan "Pindah" bila pasien tersebut ingin dirujuk untuk ditangani oleh poli yang lain'
				'Bila telah yakin bahwa informasi yang diisikan benar, klik tombol "Simpan"'
				'Anda akan dikembalikan ke halaman utama Rawat Jalan untuk melanjutkan ke pasien berikutnya'
			m \h5, 'Menu Gudang Farmasi'
			m \p, 'Adalah menu yang bisa diakses oleh baik perawat dan dokter untuk meninjau ketersediaan obat yang akan diresepkan kepada pasien, atau barang habis pakai yang tersedia untuk diminta'
			m \h5, 'Menu Amprah'
			m \p, 'Adalah menu yang bisa diakses oleh perawat untuk mengamprah kepada apotik atas barang habis pakai yang dibutuhkan'
		else if group is \obat then m \div,
			m \h5, 'Menu Apotik'
			m \p, 'Pada tabel akan terlihat daftar pasien yang sedang mengantri untuk diserahkan obat yang telah diresepkan oleh dokter'
			ols arr =
				'Klik tombol "Serah" pada salah satu baris nama yang akan diserahkan obat'
				'Pada Modal tercantum daftar nama obat, jumlah yang diminta, dan aturan pakai'
				'Bila apoteker yakin ingin menyerahkan obat, klik tombol "Serahkan"'
				'Lakukan langkah 1 sampai 4 hingga dirasa cukup untuk pengambilan obat'
				'Klik tombol "Cetak Rekap" untuk mengunduh file pdf yang bisa dicetak untuk dijadikan panduan bagi apoteker mengambil obat'
			m \h5, 'Menu Gudang Farmasi'
			m \p, 'Adalah menu yang bisa digunakan oleh apoteker untuk meninjau ketersediaan obat maupun barang habis pakai'
			m \p, 'Apoteker dapat membuka salah satu informasi obat dan mengisikan nilai "Batas Minimum" dengan cara klik ganda'
			m \h5, 'Menu Amprah'
			m \p, 'Adalah menu yang dapat digunakan oleh apoteker untuk merespon permintaan amprah dari ruangan dan mengamprah obat dan bhp ke farmasi'
			m \h6, 'Meminta barang ke Farmasi'
			ols arr =
				'Klik tombol "Request Obat" atau "Request BHP"'
				'Pada pilihan nama, tunjuk nama barang yang diinginkan'
				'Huruf "A" dan "G" yang diikuti dengan angka mewakili jumlah stok yang tersedia di "Apotik" dan "Gudang"'
				'Pada kolom jumlah, isikan jumlah barang yang dibutuhkan'
				'Bila telah yakin, klik tombol "Simpan"'
			m \h6, 'Menyerahkan barang ke Ruangan'
			ols arr =
				'Klik tombol "Serah" pada salah satu baris permintaan yang ingin direspon'
				'Pada Modal yang tercantum, muncul angka "Diminta" dan "Sedia"'
				'Isikan angka jumlah barang yang ingin diserahkan pada kolom "Diserah"'
				'Pastikan bahwa jumlah barang yang akan diserah lebih kecil dari angka "Sedia"'
				'Bila telah yakin untuk menyerahkan barangnya dalam jumlah tersebut, klik tombol "Submit"'
		else if group is \farmasi then m \div,
			m \p, 'untuk petugas gudang farmasi'
		else if group is \manajemen then m \div,
			m \p, 'untuk tim edp'
