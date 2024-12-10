#filePath = "C:\Users\admin\Documents\private\git\postgresql-17\doc\src\sgml\acronyms.sgml"
#filePath = filePath.replace("\", "\\")
import re
import db
import os

def sgml_parse(fullFileName):
    # Регурное выражение для поиска имени файла и пути егорасположения (первая строка в файле
    # ...
    fileAbsPath = os.path.split(fullFileName)[0]
    fileName = os.path.split(fullFileName)[1]

    # Регулярное выражение для поиска всех тегов (открывающих и закрывающих)
    regtag = re.compile(r"(</?\w+[\s\w|\d|\s|\"|:|//|/.|_|=]*>)", re.S)

    # Регулярное выражение для нахождения имени тега
    regtagname = re.compile(r"\w+", re.S)

    regRelPath = re.compile(r"[\w|\.|\/]+", re.S)
    #regRelPath = re.compile(r"[^(<!--)^(-->)^\s]+", re.S)

    #Открываем файл, только на чтение
    sgmlFile = open(fullFileName, 'r')

    #firstLine = sgmlFile.readline()
    fileRelPath = regRelPath.findall(sgmlFile.readline())
    #print(fileRelPath)

    doc_file_id = db.ins_doc_file (os.path.basename(fileRelPath[0]), fileRelPath[0], fullFileName )

    #Читаем содержимое файла
    content = sgmlFile.read()

    #Заведем пустое множество для сохранения всех имен тегов
    tag_set = set()

    #Найдем все теги с атрибутами
    matches = regtag.findall(content)
    #print(matches)

    #В цикле пройдем по тегам и соберем множество имен
    for val in matches:
        #print(val)
        tag_set.add(regtagname.findall(val)[0])
        #print(tagname.findall(val))

    #print(tag_set)

    for tag in tag_set:
        #Добавить новые теги в справочник тегов
        db.ins_tag(tag)
        #print(tag)

    sgmlFile.close()

###########################################################################################################

db.ins_prod("Postgresql", "PG")

db.ins_prod_vers("PG", "17.0", "bla bla bla")

db.ins_doc("PG", "17.0", 'Documentation', 'ALL_DOC', ' ole ole ole')

db.ins_doc_vers("PG_17.0_ALL_DOC", "1.0", "wow wow wow")


#...
# Здесь будет цикл по всем файлам документации
#...

# А пока запустим парсинг одного файла
sgml_parse('C:\\Users\\admin\\Documents\\private\\git\\postgresql-17\\doc\\src\\sgml\\acronyms.sgml')
