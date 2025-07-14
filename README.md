## 🛠️ Backend - Supabase

La aplicación **El Búho Turístico** utiliza [Supabase](https://supabase.io) como backend, lo que proporciona:

- **Base de datos PostgreSQL escalable y administrada.**
- **Autenticación segura con tokens JWT.**
- **Almacenamiento de archivos (avatars, fotos de sitios).**
- **Soporte para Realtime, Policies (RLS) y Triggers.**

---

### 📦 Estructura de la Base de Datos

Se crearon las siguientes tablas en Supabase, cada una con relaciones y seguridad controlada por **Row Level Security (RLS)**:

| Tabla        | Descripción |
|--------------|-------------|
| `profiles`   | Contiene información adicional de cada usuario, como `username`, `avatar_url`, `role`. Se enlaza con `auth.users` usando la columna `id`. |
| `sites`      | Tabla principal de los sitios turísticos. Cada sitio incluye título, descripción, coordenadas, y está vinculado a un usuario publicador (`user_id`). |
| `photos`     | Contiene las URLs de imágenes asociadas a un sitio (`site_id`). Se almacenan en Supabase Storage (`site-photos`). |
| `reviews`    | Reseñas que los usuarios escriben sobre un sitio. Incluye `rating`, `contenido`, `user_id`, y el `site_id` relacionado. |
| `replies`    | Respuestas a reseñas. Cada respuesta se asocia a un `review_id`. |

---

### 🔐 Autenticación y Usuarios

Se utiliza el sistema de autenticación de Supabase (email/password). Al registrarse un usuario, se dispara un **trigger** que crea automáticamente su perfil en la tabla `profiles`.

#### 🔄 Trigger de creación automática de perfil

```sql
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, username, full_name, role)
  values (
    new.id,
    new.raw_user_meta_data->>'username',
    new.raw_user_meta_data->>'full_name',
    coalesce(new.raw_user_meta_data->>'role', 'Visitante')
  );
  return new;
end;
$$ language plpgsql;

create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();
```

> 🔎 Este trigger garantiza que cada usuario tenga un perfil sincronizado sin necesidad de intervención manual.

---

### 🛡️ Seguridad con RLS (Row Level Security)

Supabase permite aplicar reglas de acceso directamente sobre la base de datos. Se usaron **políticas personalizadas** para proteger las tablas según el rol del usuario (`Visitante` o `Publicador`).

#### ✅ Ejemplo de política RLS para permitir inserción en `profiles`:

```sql
alter table public.profiles enable row level security;

create policy "Allow insert for all"
on public.profiles
for insert
with check (true);
```

> Esto asegura que incluso si el trigger es ejecutado por un rol interno (como `service_role`), pueda insertar el perfil correctamente.

---

### 📸 Supabase Storage

Se utilizaron dos buckets públicos en el módulo de almacenamiento de Supabase:

| Bucket          | Uso                           |
|-----------------|--------------------------------|
| `avatars`       | Fotos de perfil de los usuarios |
| `site-photos`   | Imágenes de los sitios turísticos |

---

### 📡 Realtime (Opcional)

Para permitir actualizaciones en tiempo real (sin recargar pantalla), se activó la replicación en las siguientes tablas desde **Database > Replication**:

- `reviews`
- `replies`

Esto permite que nuevos comentarios o respuestas aparezcan al instante en la app.

---

### 🧪 Datos de prueba (opcional)

Puedes insertar usuarios con distintos roles (`Visitante` y `Publicador`) para probar todas las funcionalidades. Al registrarse, asegúrate de enviar en el `signUp`:

```dart
await supabase.auth.signUp(
  email: 'ejemplo@email.com',
  password: '123456',
  data: {
    'username': 'johndoe',
    'full_name': 'John Doe',
    'role': 'Publicador', // o 'Visitante'
  },
);
```

> ⚠️ Si no envías el campo `role`, se asignará por defecto como `"Visitante"`.

---

### Desarrolladores:

- **Francis Aconda.**
- **Marco Tapia.**

