import pymongo
import sys

connection_string = "mongodb+srv://jorgemondra242_db_user:MHoFAf9EvQvZYlzK@kritikcluster.2pkmgqa.mongodb.net/KritikDB?retryWrites=true&w=majority"
db_name = "KritikDB"

try:
    print("Conectando a MongoDB...")
    client = pymongo.MongoClient(connection_string)
    db = client[db_name]
    
    collections = db.list_collection_names()
    print("Colecciones encontradas:", collections)
    
    for collection_name in collections:
        if collection_name != "Users":
            print(f"Eliminando colección: {collection_name}...")
            db[collection_name].drop()
        else:
            print("=> SALTANDO Users (Preservando datos de usuarios) <=")
            users_count = db["Users"].count_documents({})
            print(f"   (Usuarios conservados: {users_count})")
            
    print("\n¡Limpieza Terminada! Ya puedes meter datos limpios.")
    
except Exception as e:
    print("Error conectando a la BD:", e)
