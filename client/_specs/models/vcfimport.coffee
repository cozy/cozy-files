describe 'vCard Import', ->

    Contact = require 'models/contact'
    ContactView = require 'views/contact'

    gContactVCF = """
        BEGIN:VCARD
        VERSION:3.0
        FN:Test Contact
        N:Contact;Test;;;
        EMAIL;TYPE=INTERNET;TYPE=HOME:test@example.com
        EMAIL;TYPE=INTERNET;TYPE=WORK:test2@example.com
        TEL;TYPE=CELL:0600000000
        TEL;TYPE=WORK:0610000000
        ADR;TYPE=HOME:;;1 Sample Adress;PARIS;;75001;FRANCE
        ADR;TYPE=WORK:;;2 Sample Address;PARIS;;75002;FRANCE
        ORG:MyCompany
        BDAY:1989-02-02
        item1.URL:http\\://test.example.com
        item1.X-ABLabel:PROFILE
        item2.EMAIL;TYPE=INTERNET:test3@example.com
        item2.X-ABLabel:truc
        item3.X-ABDATE:2013-03-14
        item3.X-ABLabel:_$!<Anniversary>!$_
        X-UNKNOWN:test
        TITLE:CEO
        END:VCARD
        """

    aContactVCF = """
        BEGIN:VCARD
        VERSION:3.0
        N:LAVOINE;Marc;;;
        FN:Marc LAVOINE
        EMAIL;type=INTERNET;type=WORK;type=pref:monemail@email.com
        TEL;type=WORK;type=pref:06 00 00 00 00
        item1.ADR;type=HOME;type=pref:;;Rue machin truc;Lille;;62000;France
        item1.X-ABADR:fr
        NOTE:<HTCData><Facebook>id\\:1553000000/friendof\\:1282000000</Facebook></HTCData>
        CATEGORIES:AD
        X-ABUID:D6B944A1-7E42-44B7-9478-F15988FF84D2\\:ABPerson
        END:VCARD
        BEGIN:VCARD
        VERSION:3.0
        N:CRESSON;Siron;;;
        FN:Siron CRESSON
        EMAIL;type=INTERNET;type=HOME;type=pref:monemail@msn.com
        TEL;type=CELL;type=pref:06 00 00 00 00
        item1.ADR;type=WORK;type=pref:;;43 rue blabla;Paris;;750000;France
        item1.X-ABADR:fr
        NOTE:<HTCData><Facebook>id\\:1553000000/friendof\\:1553000000</Facebook></HTCData>
        CATEGORIES:AD
        X-ABUID:DDEE40FC-202E-4B01-8124-CB9B7C680601\\:ABPerson
        END:VCARD
    """


    it 'should parse a Google Contacts vCard', ->

        gContact = Contact.fromVCF gContactVCF

        expect(gContact.length).to.equal 1

        @contact = contact = gContact.at 0

        expect(contact.attributes).to.have.property 'fn', 'Test Contact'
        expect(contact.dataPoints).to.have.length 11

        dp = contact.dataPoints.findWhere
            name: 'url'
            type: 'profile'
            value: 'http://test.example.com'
        expect(dp).to.not.be.an 'undefined'

        dp = contact.dataPoints.findWhere
            name: 'email'
            type: 'truc'
            value: 'test3@example.com'
        expect(dp).to.not.be.an 'undefined'

    it 'and the generated contact should not bug ContactView', ->

        new ContactView(model : @contact).render()


    it 'should parse Apple Conctacs vCard', ->

        aContact = Contact.fromVCF aContactVCF

        expect(aContact).to.have.length 2

        @contact = contact = aContact.at 0

        expect(contact.attributes).to.have.property 'fn', 'Marc LAVOINE'

        console.log contact.dataPoints.toJSON()

        expect(contact.dataPoints).to.have.length 3

        dp = contact.dataPoints.findWhere
            name: 'adr'
            type: 'home'
            value: "Rue machin truc\nLille\n62000\nFrance"


    it 'and the generated contact should not bug ContactView', ->

        new ContactView(model : @contact).render()