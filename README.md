# proto-argot
Developing shared data submission format

# What is here?
* README contains key from record number (used to name files) to brief description of the record
.* Record number links to this record in the Endeca reference implementation -- shows result of mapping Endeca prepipeline vertical delimited format into actual Endeca data model 
* Files for each record (file names are based on record number):
.* .mrc - MARC file for each record
.* *_mrk.txt - MARCEdit Mnemonic (human readable) version of each MARC record
.* *_end.txt - Endeca prepipeline vertical delimited format for each record

# Notes/caveats
* Only the first item record (945 field) is being exported from Millennium client when I manually export records to create the .mrc and *_mrk.txt files. I will update these when I'm able to get MARC or MARC-XML happening from the backend.

# Records
* [b1304177](http://trlnr610c.trln.org:8888/endeca_jspref/controller.jsp?sid=13704A964F65&enePort=8070&R=UNCb1304177&eneHost=trlnr610c.trln.org) - [TRLN](http://search.trln.org/search?id=UNCb1304177) - [UNC](http://search.lib.unc.edu/search?R=UNCb1304177) - Serial; Russian/Cyrillic vernacular; 2 instances of 710 field, both with associated 880
* [b5344382]() - TRLN - UNC - ebook x x v x r3
* - TRLN - UNC - Bib record for archival collection with EAD data merged in. *currently EAD data/merge is busted*
