if Meteor.isClient

	@rights = [
		group: \regis
		list: <[ regis ]>
	,
		group: \bayar
		list: [\bayar]
	,
		group: \jalan
		list: <[ jalan farmasi amprah ]>
	,
		group: \inap
		list: <[ inap farmasi amprah ]>
	,
		group: \labor
		list: [\labor]
	,
		group: \radio
		list: [\radio]
	,
		group: \obat
		list: <[ obat farmasi amprah ]>
	,
		group: \rekam
		list: <[ rekam regis ]>
	,
		group: \admisi
		list: [\admisi]
	,
		group: \manajemen
		list: [\manajemen]
	,
		group: \farmasi
		list: <[farmasi amprah]>
	,
		group: \depook
		list: <[depook farmasi amprah]>
	,
		group: \radio
		list: <[amprah]>
	,
		group: \labor
		list: <[amprah]>
	,
		group: \gizi
		list: <[amprah]>
	,
		group: \cssd
		list: <[amprah]>
	,
		group: \bedah
		list: <[amprah]>
	,
		group: \icu
		list: <[amprah]>
	,
		group: \perina
		list: <[amprah]>
	,
		group: \laundry
		list: <[amprah]>
	,
		group: \jenazah
		list: <[amprah]>
	,
		group: \promosi
		list: <[amprah]>
	,
		group: \logistik
		list: <[amprah]>
	]map (i) -> _.assign i, list:
		[...i.list, \panduan]
