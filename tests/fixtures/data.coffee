sampleaddress = '14 Avenue de la République, 60200 Compiègne, Picardie, France'


makeLog = (tsp, dir, nb, dur) ->
    timestamp: tsp
    direction: dir
    remote: tel: nb
    content: duration: dur
    type: 'VOICE'

module.exports =

    contact1:
        fn: "John Smith"
        note: "notes"
        datapoints: [
            {name: 'tel'  , type: 'home', value: '+331234567'}
            {name: 'tel'  , type: 'work', value: '12584367'}
            {name: 'email', type: 'home', value: 'jsmith@test.com'}
            {name: 'adr'  , type: 'home', value: sampleaddress}
        ]


    logs1: [
        makeLog '2007-05-13T16:49:01.000Z', 'INCOMING', '331234567', '00:05:00'
        makeLog '2007-06-13T16:49:01.000Z', 'OUTGOING', '331234567', '00:02:00'
        makeLog '2007-07-13T16:49:01.000Z', 'INCOMING', '331234500', '01:05:00'
        ]

module.exports.logs2 = module.exports.logs1.concat [
        makeLog '2007-08-13T16:49:01.000Z', 'OUTGOING', '331234567', '00:02:00'
        ]

module.exports.logsOrange = [
    {
        timestamp: '2007-05-13T16:49:01.000Z',
        direction:'INCOMING',
        correspondantNumber:'331234567',
        duration:'00:05:00',
        origin:'Orange',
        type: 'VOICE'
        snippet: '2007-05-13T16:49:01.000Z : VOICE INCOMING 331234567'

    },{
        timestamp: '2007-06-13T16:49:01.000Z',
        direction:'OUTGOING',
        correspondantNumber:'331234567',
        duration:'00:02:00',
        origin:'Orange',
        type: 'VOICE'
        snippet: '2007-06-13T16:49:01.000Z : VOICE OUTGOING 331234567'
    },{
        timestamp: '2007-06-13T16:49:01.000Z',
        direction:'OUTGOING',
        correspondantNumber:'331232367',
        duration:'00:02:00',
        origin:'Orange',
        type: 'SMS-M'
        snippet: '2007-06-13T16:49:01.000Z : SMS-M OUTGOING 331232367'
    }
]
