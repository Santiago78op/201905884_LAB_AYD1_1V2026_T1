from flask import Flask

# Instancia de la aplicación Flask
app = Flask(__name__)

# Ruta de la aplicación
@app.route('/home')
def album_love():
    name = "Santiago Barrera"
    album = "Surfer Rosa"
    return f"Hola, soy {name} y mi álbum favorito es {album}."

# Ejecutar la aplicación
if __name__ == '__main__':
    # Modo debug: si hay error lo muestra en el navegador y recarga auto el cod.
    app.run(debug=True)