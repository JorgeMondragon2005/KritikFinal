import pymongo
import bcrypt
import datetime
from bson.objectid import ObjectId

connection_string = "mongodb+srv://jorgemondra242_db_user:MHoFAf9EvQvZYlzK@kritikcluster.2pkmgqa.mongodb.net/KritikDB?retryWrites=true&w=majority"
db_name = "KritikDB"

print("Conectando a MongoDB para restaurar datos iniciales...")
client = pymongo.MongoClient(connection_string)
db = client[db_name]

# Helper para encriptar claves
def hash_password(password):
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

# LIMPIEZA TOTAL (INCLUYENDO USUARIOS)
print("Limpiando todas las colecciones para evitar duplicados...")
for coll in db.list_collection_names():
    db[coll].drop()

# 1. USUARIOS
print("Creando Usuarios VIP (Admin, Profesor, Alumnos)...")
users = [
    {
        "_id": ObjectId(),
        "Email": "admin@kritik.com",
        "PasswordHash": hash_password("admin123"),
        "FullName": "Administrador Supremo",
        "Role": "Admin",
        "IsEmailVerified": True,
        "VerificationCode": "123456",
        "Bio": "Gestor principal del sistema"
    },
    {
        "_id": ObjectId(),
        "Email": "profesor@kritik.com",
        "PasswordHash": hash_password("profe123"),
        "FullName": "Profesor Alan Turing",
        "Role": "Evaluator",
        "IsEmailVerified": True,
        "VerificationCode": "123456",
        "Bio": "Evaluador Senior de Proyectos de Software"
    },
    {
        "_id": ObjectId(),
        "Email": "alumno1@kritik.com",
        "PasswordHash": hash_password("student123"),
        "FullName": "Bill Gates (Estudiante)",
        "Role": "Student",
        "IsEmailVerified": True,
        "VerificationCode": "123456",
        "Bio": "Estudiante de Ingeniería"
    },
    {
        "_id": ObjectId(),
        "Email": "alumno2@kritik.com",
        "PasswordHash": hash_password("student123"),
        "FullName": "Linus Torvalds (Estudiante)",
        "Role": "Student",
        "IsEmailVerified": True,
        "VerificationCode": "123456",
        "Bio": "Estudiante de Código Abierto"
    }
]

db["usuario"].insert_many(users)
admin_id = str(users[0]["_id"])
profesor_id = str(users[1]["_id"])
alumno1_id = str(users[2]["_id"])
alumno2_id = str(users[3]["_id"])

# 2. RUBRICAS
print("Creando Rúbricas...")
rubrics = [
    {
        "_id": ObjectId(),
        "name": "Rúbrica Estándar de Software",
        "items": [
            {"criteria": "Funcionalidad", "maxPoints": 40, "description": "¿El sistema cumple los requisitos básicos sin errores?"},
            {"criteria": "Diseño UX/UI", "maxPoints": 30, "description": "¿La interfaz es estética y fácil de navegar?"},
            {"criteria": "Innovación", "maxPoints": 30, "description": "¿La solución es original frente al mercado actual?"}
        ],
        "isGlobal": True,
        "creatorId": profesor_id
    }
]
db["rubrics"].insert_many(rubrics)
rubric1_id = str(rubrics[0]["_id"])

# 3. ASIGNACIONES (TAREAS/CONVOCATORIAS)
print("Creando Convocatorias...")
assignments = [
    {
        "_id": ObjectId(),
        "Title": "Feria de Ciencias 2026 - Backend",
        "Description": "Entrega final del proyecto de la materia de Sistemas Distribuidos.",
        "DueDate": datetime.datetime.utcnow() + datetime.timedelta(days=15),
        "IsActive": True,
        "AllowedCategories": ["Desarrollo Web", "Inteligencia Artificial", "Móvil"],
        "RubricId": rubric1_id,
        "EvaluatorIds": [profesor_id]
    }
]
db["assignments"].insert_many(assignments)
assignment1_id = str(assignments[0]["_id"])

# 4. PROYECTOS (ENTREGAS DE ALUMNOS)
print("Creando Proyectos de Alumnos...")
projects = [
    {
        "_id": ObjectId(),
        "AssignmentId": assignment1_id,
        "Title": "Marketplace Universitario",
        "TeamName": "Los Duros",
        "Category": "Desarrollo Web",
        "Description": "Plataforma de compra-venta exclusiva para estudiantes con pagos integrados.",
        "Technologies": ["React", "Node.js", "MongoDB"],
        "TeamMembers": [
            {"Name": "Bill Gates", "Role": "Líder", "UserId": alumno1_id}
        ],
        "RepoUrl": "https://github.com/test/marketplace",
        "VideoUrl": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
        "Images": [],
        "CreatedAt": datetime.datetime.utcnow()
    },
    {
        "_id": ObjectId(),
        "AssignmentId": assignment1_id,
        "Title": "IA para Detección de Plagas",
        "TeamName": "GreenTech",
        "Category": "Inteligencia Artificial",
        "Description": "Un modelo de visión por computadora que ayuda a agricultores a identificar enfermedades en las hojas.",
        "Technologies": ["Python", "TensorFlow", "Flutter"],
        "TeamMembers": [
            {"Name": "Linus Torvalds", "Role": "Desarrollador AI", "UserId": alumno2_id}
        ],
        "RepoUrl": "https://github.com/test/plagas",
        "VideoUrl": "",
        "Images": [],
        "CreatedAt": datetime.datetime.utcnow()
    }
]
db["projects"].insert_many(projects)

print("=========================================")
print("DATOS DE PRUEBA INYECTADOS CON EXITO")
print("=========================================")
print("Usa estas credenciales para entrar a la App:")
print(" - Admin: admin@kritik.com | Clave: admin123")
print(" - Profe: profesor@kritik.com | Clave: profe123")
print(" - Alumno 1: alumno1@kritik.com | Clave: student123")
print(" - Alumno 2: alumno2@kritik.com | Clave: student123")
