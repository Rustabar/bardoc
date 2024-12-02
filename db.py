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

# inserting a new version
def ins_vers(versname, versnum, rewrite=True):
    conn = pgconn()
    cur = conn.cursor()
    cur.execute("INSERT into doc.doc_vers(vers_name, vers_num) " +
                "select '" + versname + "', '" + versnum + "'" +
                "where not exists (select 1 from doc.tag where tag_name = '" + tagname + "' );")
    #commiting
    cur.execute("commit;")
    cur.close()
    conn.close()


# inserting a new file
def ins_file(fileAbsPath, fileName, vers_id, fileRelPath="", rewrite=True):
    conn = pgconn()
    cur = conn.cursor()
    cur.execute("INSERT into doc.file(file_name, file_abspath, file_relpath, vers_id) "  +
                "select '" + fileName + "', '" + fileAbsPath + "', nullif('" + fileRelPath + "', ''), " + vers_id + ""
                "where not exists (select 1 from doc.file where file_name = '" + tagname + "' );")
    #commiting
    cur.execute("commit;")
    cur.close()
    conn.close()

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

ins_tag("test3")






