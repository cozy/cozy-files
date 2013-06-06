sampleaddress = 'Box3;Suite215;14 Avenue de la République;Compiègne;Picardie;60200;France'


module.exports =

  contact1:
      fn: "John Smith"
      note: "notes"
      datapoints: [
        {name: 'tel'  , type: 'home', value: '000'}
        {name: 'tel'  , type: 'work', value: '111'}
        {name: 'email', type: 'home', value: 'jsmith@test.com'}
        {name: 'adr'  , type: 'home', value: sampleaddress}
      ]
