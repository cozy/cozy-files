sampleaddress = 'Box3;Suite215;14 Avenue de la République;Compiègne;Picardie;60200;France'


module.exports =

  contact1:
      name: "John Smith"
      notes: "notes"
      datapoints: [
        {name: 'phone', type: 'home', value: '000'}
        {name: 'phone', type: 'work', value: '111'}
        {name: 'email', type: 'home', value: 'jsmith@test.com'}
        {name: 'smail', type: 'home', value: sampleaddress}
      ]
