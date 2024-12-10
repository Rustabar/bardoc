import psycopg2
import creds

# connecting to pg database
# return connector
def pgconn ():
    return psycopg2.connect(
        dbname=creds.PGDBNAME,
        user=creds.PGDBUSER,
        host=creds.PGDBHOST,
        port=creds.PGDBPORT
    )

# inserting new product
def ins_prod(prod_name, prod_code):
    conn = pgconn()
    cur = conn.cursor()
    cur.execute("select prod.prod_i('" + prod_name + "', '" + prod_code + "');")
    prod_id = cur.fetchone()[0]
    cur.execute("commit;")
    cur.close()
    conn.close()
    return prod_id

# inserting new product version
def ins_prod_vers(prod_code, prod_vers_num, prod_vers_desc):
    conn = pgconn()
    cur = conn.cursor()
    cur.execute("select prod.prod_vers_i(prod.prod_id_by_code('" + prod_code + "'), '" + prod_vers_num + "', '" + prod_vers_desc + "');")
    prod_vers_id = cur.fetchone()[0]
    cur.execute("commit;")
    cur.close()
    conn.close()
    return prod_vers_id

# inserting a new doc version
def ins_doc(prodcode, prodversnum, docname, doccode, docdesc):
    conn = pgconn()
    cur = conn.cursor()
    cur.execute("select doc.doc_i(prod.get_prod_vers_id('" + prodcode + "', '" + prodversnum + "'), '" + docname + "', '" + doccode + "', '" + docdesc + "');")
    doc_id = cur.fetchone()[0]
    #commiting
    cur.execute("commit;")
    cur.close()
    conn.close()
    return doc_id

# inserting a new doc version
def ins_doc_vers(docfullcode, docversnum, docversdesc):
    conn = pgconn()
    cur = conn.cursor()
    cur.execute("select doc.doc_vers_i(doc.doc_id_by_code('" + docfullcode + "'), '" + docversnum + "', '" + docversdesc + "');")
    doc_vers_id = cur.fetchone()[0]
    #commiting
    cur.execute("commit;")
    cur.close()
    conn.close()
    return doc_vers_id


# inserting a new file
def ins_doc_file(fileName, fileAbsPath, fileRelPath=""):
    conn = pgconn()
    cur = conn.cursor()
    cur.execute("select doc.doc_file_i('" + fileName + "', '" + fileAbsPath + "', '" + fileRelPath + "');")
    doc_file_id = cur.fetchone()[0]
    #print(doc_file_id)
    #commiting
    cur.execute("commit;")
    cur.close()
    conn.close()
    return doc_file_id

# inserting a new tag
def ins_tag(tagname):
    conn = pgconn()
    cur = conn.cursor()
    cur.execute("INSERT into doc.tag(tag_name) "  +
                "select '" + tagname + "'  " +
                "where not exists (select 1 from doc.tag where tag_name = '" + tagname + "' );")
    #commiting
    cur.execute("commit;")
    cur.close()
    conn.close()

#ins_tag("test3")

#ins_prod("Postgresql", "PG")
