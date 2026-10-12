# Hoja de ruta de seguridad para Firestore

> **Recordatorio para futuras sesiones:** antes de cambiar `firestore.rules`, revisar este documento. La siguiente mejora pendiente es aislar la lectura de datos por expedición y sacar las solicitudes de unión de los documentos `outings`.

## Estado actual

Las reglas actuales están desplegadas en el proyecto Firebase `gems-36f6d` desde `firestore.rules`.

Actualmente:

- Las lecturas requieren autenticación, pero cualquier usuario autenticado puede leer las colecciones de la aplicación.
- Las escrituras de registros exigen que el usuario sea miembro de la expedición.
- Un registro solo puede ser modificado o eliminado por su autor o por un administrador.
- El creador o un administrador puede modificar y eliminar expediciones.
- Las solicitudes de unión se almacenan dentro del arreglo `pendingUsers` del documento de la expedición.
- El rol de administrador se obtiene de `users/{uid}.role == "admin"`.

## Motivo de la limitación

La aplicación actual descarga todas las expediciones con una consulta global y luego descarga los registros filtrando por `outingId` desde los adaptadores remotos. Las reglas de Firestore no funcionan como filtros posteriores: una consulta debe ser compatible con la regla para todos sus posibles resultados.

Por eso las reglas actuales no pueden aislar completamente la lectura por expedición sin cambiar primero las consultas de la aplicación.

## Mejoras pendientes

### 1. Filtrar siempre las consultas por expedición

Actualizar los adaptadores y servicios para que las consultas de registros siempre incluyan:

```dart
where('outingId', isEqualTo: outingId)
```

Evitar consultas globales de `bird_records`, `rock_records`, `soil_records`, `vegetation_records`, `water_records` y `social_records`.

Después, cambiar las reglas para que la lectura de un registro solo sea válida si el usuario pertenece a la expedición referenciada por `outingId`.

La regla objetivo debe tener una forma equivalente a:

```text
allow read: if isOutingMember(resource.data.outingId);
```

Debe validarse con el emulador de Firebase antes de desplegarla, porque las consultas deben incluir las restricciones que las reglas necesitan demostrar.

### 2. Separar las solicitudes de unión

Migrar las solicitudes pendientes desde el arreglo `outings.pendingUsers` a una subcolección:

```text
outings/{outingId}/joinRequests/{userId}
```

Cada documento debería contener como mínimo:

```text
userId
name
email
status: "pending"
createdAt
```

Ventajas:

- Un usuario solo puede crear o cancelar su propia solicitud.
- El propietario de la expedición puede aprobar o rechazar solicitudes.
- Se evita que un miembro modifique o elimine solicitudes de otros usuarios.
- Se eliminan actualizaciones concurrentes sobre un arreglo compartido.

### 3. Usar Custom Claims para administradores

Como mejora posterior, mover el rol administrativo desde `users/{uid}.role` a un Custom Claim de Firebase Auth:

```text
request.auth.token.admin == true
```

El claim debe asignarse únicamente desde un entorno confiable, como Firebase Admin SDK o una función backend. Nunca debe poder modificarlo directamente la aplicación móvil.

### 4. Validar la forma de los documentos

Agregar validaciones de campos obligatorios y tipos para:

- `users`
- `outings`
- `joinRequests`
- registros biológicos
- especies

Por ejemplo, validar que un registro tenga `outingId`, `userId` y `recordedAt`, y que el cliente no pueda cambiar `userId` ni `outingId` durante una actualización.

### 5. Añadir pruebas de reglas

Crear pruebas con Firebase Emulator Suite para verificar como mínimo:

- Usuario no autenticado rechazado.
- Usuario autenticado leyendo su expedición permitida.
- Usuario fuera de una expedición rechazado.
- Usuario creando un registro dentro de una expedición permitida.
- Usuario intentando usar el `userId` de otra persona rechazado.
- Autor actualizando su propio registro.
- Usuario distinto intentando modificarlo rechazado.
- Administrador gestionando expediciones y registros.
- Usuario modificando solicitudes de unión ajenas rechazado.

## Orden recomendado

1. Cambiar primero las consultas para trabajar siempre por `outingId`.
2. Migrar `pendingUsers` a `joinRequests`.
3. Probar reglas con el emulador.
4. Desplegar las reglas nuevas en un proyecto de pruebas.
5. Probar con dos usuarios y dos expediciones distintas.
6. Desplegar en `gems-36f6d`.

## Despliegue actual

Para publicar las reglas actuales:

```bash
firebase deploy --only firestore:rules --project gems-36f6d
```

No reemplazar las reglas por `allow read, write: if true;` en producción.
