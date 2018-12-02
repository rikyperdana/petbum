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
	]

	_.map rights, (i) -> _.assign i,
		list: [...i.list, \panduan]
