import pymongo
import sys

connection_string = "mongodb+srv://jorgemondra242_db_user:MHoFAf9EvQvZYlzK@kritikcluster.2pkmgqa.mongodb.net/KritikDB?retryWrites=true&w=majority"
db_name = "KritikDB"

try:
    print("Conectando a MongoDB para VACIADO ABSOLUTO...")
    client = pymongo.MongoClient(connection_string)
    db = client[db_name]
    
    collections = db.list_collection_names()
    print("Colecciones encontradas:", collections)
    
    print("Limpiando ABSOLUTAMENTE TODAS las colecciones (incluyendo Usuarios)...")
    for coll in collections:
        print(f"Borrando colección: {coll}...")
        db[coll].drop()
        
    print("=========================================")
    print("BASE DE DATOS VACIADA POR COMPLETO")
    print("=========================================")
    
except Exception as e:
    print("Error conectando a la BD:", e)
