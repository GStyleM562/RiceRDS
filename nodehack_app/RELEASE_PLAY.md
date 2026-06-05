# Publicar en Google Play — Prueba interna (Null Protocol: Duel)

Guía para sacar la **primera build de prueba interna**. Lo técnico ya quedó
preparado en el repo; aquí están los pasos que faltan (la mayoría los haces tú,
porque dependen de tu cuenta y tus llaves).

## Ya preparado en el repo ✅
- **Permiso de Internet** en el manifest (sin esto el PVP NO funciona en release).
- **Nombre**: `Null Protocol` bajo el ícono. (Título en la tienda: `Null Protocol: Duel`.)
- **Firma de release** cableada en `android/app/build.gradle.kts` (lee `android/key.properties`).
- **Política de privacidad** redactada en `nodehack_app/PRIVACY.md`.
- `key.properties`, `*.jks` y `*.keystore` ya están en `.gitignore` (las llaves nunca se suben).

## Decisiones que faltan (tú)
1. **ID de aplicación (permanente):** ahora es `com.riceprotocolstudio.nodehack_app`.
   Funciona, pero si prefieres uno más limpio (p. ej. `com.riceprotocolstudio.nullprotocolduel`)
   hay que cambiarlo **antes** de la primera subida (después ya no se puede). Dime si lo cambio.
2. **Política de privacidad:** necesita una **URL pública**. Opciones fáciles y gratis:
   GitHub Pages, o pegar el texto de `PRIVACY.md` en una página/Notion público. Pásame la URL.

## Paso 1 — Crear la llave de subida (una sola vez)
Genera un keystore. **Guarda el archivo y las contraseñas en un lugar seguro**
(si los pierdes, no podrás actualizar la app salvo reseteo de Play App Signing).

```powershell
# Desde nodehack_app/  — crea la llave (válida 27+ años). Te pedirá contraseñas y datos.
keytool -genkey -v -keystore upload-keystore.jks -storetype JKS `
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Luego crea `nodehack_app/android/key.properties` (NO se versiona) con:

```properties
storePassword=TU_CONTRASEÑA_DEL_STORE
keyPassword=TU_CONTRASEÑA_DE_LA_LLAVE
keyAlias=upload
storeFile=../upload-keystore.jks
```

> `storeFile` es relativo a `android/`. Si dejas el `.jks` en la raíz de
> `nodehack_app/`, la ruta es `../upload-keystore.jks` (como arriba).

## Paso 2 — Construir el App Bundle (AAB) firmado
Google Play recibe **.aab**, no .apk.

```powershell
cd nodehack_app
flutter build appbundle --release
# Resultado: build/app/outputs/bundle/release/app-release.aab
```

(Lo puedo correr yo en cuanto exista `key.properties`.)

## Paso 3 — Crear la app en Play Console
1. Entra a **play.google.com/console** (tu misma cuenta de "Node Protocol").
2. **Crear app** → nombre `Null Protocol: Duel`, idioma, tipo **Juego**, gratis.
3. Acepta las declaraciones.

## Paso 4 — Llenar lo mínimo obligatorio (te dejo las respuestas)
- **Política de privacidad:** pega la URL del Paso de decisiones.
- **Data safety / Seguridad de los datos:**
  - ¿Recopila o comparte datos? **Sí recopila, no comparte.**
  - Datos: "Otros — alias para mostrar" (opcional, no compartido) y un id de
    dispositivo anónimo. **Cifrados en tránsito: Sí.** **Eliminables: sí** (al
    desinstalar). **No** para publicidad/analítica.
- **Clasificación de contenido (IARC):** juego de cartas/estrategia, **sin**
  violencia/sexo/apuestas/drogas → saldrá apto para todos (PEGI 3 / ESRB E).
- **Público objetivo:** 13+ (para no entrar en requisitos de apps para niños).
- **App de gobierno / finanzas / salud:** No.
- **Anuncios:** No contiene anuncios.

## Paso 5 — Ficha de tienda (mínimo para probar)
- **Título:** Null Protocol: Duel
- **Descripción corta** (≤80) y **completa**: te las redacto cuando quieras.
- **Ícono 512×512**, **gráfico destacado 1024×500**, y **2+ capturas** de teléfono.
  *(Para prueba interna basta material básico; si no lo tienes aún, lo dejamos
  simple y lo mejoramos después — el nombre y los gráficos se cambian cuando sea.)*

## Paso 6 — Subir a Prueba interna
1. Menú **Pruebas → Prueba interna** → **Crear versión**.
2. Sube el `app-release.aab`.
3. Agrega tu correo (y los de tus testers) a la **lista de testers**.
4. Revisa y **publica**. Te da un **enlace de aceptación**; cada tester lo abre,
   acepta y descarga desde Play.

## Notas
- **targetSdk**: lo fija Flutter; la versión actual cumple el mínimo de Play.
- **Servidor por defecto**: el app ya apunta a `wss://nodehack-server.onrender.com/ws`
  (TLS), perfecto para testers en cualquier red. *(El modo LAN `ws://` no funciona
  en release por la política de tráfico en claro; para PVP por internet no hace falta.)*
- **Versión**: por release, sube el build number en `pubspec.yaml` (`1.0.0+1` → `+2`…).
