# Chuleta de Git (para trabajar entre laptop y PC)

## Antes de empezar a trabajar (en cualquiera de las 2 maquinas)

```bash
git pull
```

Trae los cambios que la otra maquina haya subido. Evita partir de una version vieja.

## Cuando termines de trabajar (si quieres que la otra maquina pueda continuar)

```bash
git add -A
git commit -m "descripcion breve de lo que hiciste"
git push
```

- `git add -A` -> marca todos los archivos nuevos/modificados para guardar.
- `git commit` -> guarda una "foto" de esos cambios en tu historial LOCAL (todavia no sube nada a GitHub).
- `git push` -> sube esa foto a GitHub para que la otra maquina la pueda bajar.

## Revisar el estado antes de comitear (recomendado)

```bash
git status
```

Muestra que archivos estan modificados (`M`), nuevos sin trackear (`??`), o listos para comitear.

## Si git pide identidad (solo la primera vez en una maquina nueva)

```bash
git config user.name "Tu Nombre"
git config user.email "tu@correo.com"
```

## Mental model rapido

```
[Laptop]  <-->  [GitHub, la nube]  <-->  [PC]
```

GitHub es el punto de encuentro. A diferencia de OneDrive, la sincronizacion
con GitHub NO es automatica: hay que hacer `pull` para bajar y `push` para subir.

## Si git dice que hay conflicto al hacer pull

Significa que el mismo archivo se edito en ambas maquinas sin sincronizar antes.
No entrar en panico: pedir ayuda para revisar el archivo y fusionar los cambios
a mano antes de comitear.
