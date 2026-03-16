# Endpoint de likes (fallback cuando Firestore está offline en web)

La app Flutter llama a este endpoint cuando, tras refrescar la página, el cliente Firestore web falla con "client is offline" al cargar el número de likes y si el usuario dio like. El backend lee en Firestore (servidor) y devuelve los datos.

## Especificación

**Método y ruta:** `GET /api/gallery/event/:eventId/photo/likes`

**Query params:**
- `likesKey` (string): clave estable de la foto (ej. `https___res_cloudinary_com_..._jpg`). Es el mismo valor que se usa en Firestore en `events/{eventId}/photos/{likesKey}/likes/{userId}`.
- `userId` (string): id del usuario actual (para saber si `userLiked` es true).

**Respuesta exitosa (200):**
```json
{
  "count": 1,
  "userLiked": true
}
```

- `count`: número de documentos en la subcolección `events/{eventId}/photos/{likesKey}/likes`.
- `userLiked`: true si existe el documento `events/{eventId}/photos/{likesKey}/likes/{userId}`.

**Ejemplo de implementación (Node/Express + Admin SDK):**
```js
// Firestore: events/{eventId}/photos/{likesKey}/likes/{userId}
app.get('/api/gallery/event/:eventId/photo/likes', async (req, res) => {
  const { eventId } = req.params;
  const { likesKey, userId } = req.query;
  if (!eventId || !likesKey) return res.status(400).json({ error: 'eventId and likesKey required' });
  try {
    const likesRef = admin.firestore()
      .collection('events').doc(eventId)
      .collection('photos').doc(likesKey)
      .collection('likes');
    const [snap, userDoc] = await Promise.all([
      likesRef.get(),
      userId ? likesRef.doc(userId).get() : Promise.resolve(null),
    ]);
    res.json({
      count: snap.size,
      userLiked: userDoc?.exists ?? false,
    });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});
```

Si este endpoint no existe o devuelve error, la app seguirá mostrando 0 likes tras el fallback (no rompe nada).
