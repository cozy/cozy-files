Client = require('request-json').JsonClient
@client = new Client "http://localhost:9101/"
if process.env.NODE_ENV is "production" or process.env.NODE_ENV is "test"
	@client.setBasicAuth process.env.NAME, process.env.TOKEN

module.exports = () =>	
    data =  
    	filter :
    		"function (doc, req) {\n" +
            "    if(doc._deleted) {\n" +
            "        return true; \n" +
            "    }\n" +
            "    if ((doc.docType && doc.docType === \"File\") " + 
            " || (doc.docType && doc.docType === \"Folder\")) {\n" +
            "        return true; \n"+
            "    } else { \n" +
            "        return false; \n" +
            "    }\n" +
            "}"
    @client.put "filter/filesfilter/", data, ()->