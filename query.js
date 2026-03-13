const { MongoClient } = require('mongodb');
const uri = "mongodb+srv://jorgemondra242_db_user:MHoFAf9EvQvZYlzK@kritikcluster.2pkmgqa.mongodb.net/KritikDB?retryWrites=true&w=majority";

async function run() {
  const client = new MongoClient(uri);
  try {
    await client.connect();
    const db = client.db('KritikDB');
    
    // Encuentra todos los usuarios
    const users = await db.collection('usuario').find({}).toArray();
    
    // Filtra los que NO contengan 'isaac' ni 'fabricio' en el email (case insensitive)
    const emailsToDelete = users
      .map(u => u.Email)
      .filter(email => {
        const lowerEmail = email.toLowerCase();
        return !lowerEmail.includes('isaac') && !lowerEmail.includes('fabricio');
      });

    if (emailsToDelete.length > 0) {
      const result = await db.collection('usuario').deleteMany({
        Email: { $in: emailsToDelete }
      });
      console.log(`Eliminados ${result.deletedCount} usuarios con éxito.`);
    } else {
      console.log("No había correos extra para eliminar.");
    }
    
    console.log("\nLista actualizada de correos que SI sobrevivieron en la BD:");
    const remainingUsers = await db.collection('usuario').find({}).toArray();
    remainingUsers.forEach(u => console.log(`- ${u.Email}`));
    
  } finally {
    await client.close();
  }
}
run().catch(console.dir);
