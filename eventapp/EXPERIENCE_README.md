# Wedding App — Visión de producto y roadmap por releases

## Posicionamiento


Todo lo importante del matrimonio, en un solo lugar: antes, durante y después del gran día.

## 1. Qué es Wedding App

Wedding App es una aplicación privada por matrimonio que concentra en una sola experiencia todo lo necesario para organizar, comunicar, vivir y recordar el evento.

No es solo una invitación digital.
No es solo una página con información.
No es solo una galería de fotos.

Es la capa digital del matrimonio.

Permite que:
- los novios administren el evento, los invitados y la información oficial,
- los invitados accedan a una experiencia personalizada desde un enlace único con URL estable (`eventapp.com/{id_boda}/{id_invitación}` checklist y `.../invite` para confirmacion),
- el evento se viva de forma más ordenada, más conectada y más memorable,
- el matrimonio no termine al apagar la música, sino que quede guardado como una experiencia compartida.

## 2. Problema que resuelve

Hoy la experiencia digital de un matrimonio suele estar fragmentada en muchos lugares distintos:
- la invitación llega por un canal,
- la ubicación por otro,
- la confirmación de asistencia por WhatsApp,
- las restricciones alimentarias por mensaje,
- la lista de regalos en otro link,
- las fotos quedan dispersas entre teléfonos, chats y redes sociales,
- y durante el evento no existe un espacio vivo que conecte a todos.

Eso genera problemas para todos:

**Para los novios**

- cuesta manejar invitados y confirmaciones,
- cuesta saber quién tiene +1 y quién no,
- cuesta ordenar restricciones alimentarias,
- cuesta comunicar cambios o avisos importantes,
- cuesta centralizar recuerdos del evento.

**Para los invitados**

- no siempre tienen claro qué hacer,
- pueden perder información importante,
- muchas veces no se sienten reconocidos personalmente,
- no tienen un lugar único donde vivir la experiencia del matrimonio.

Wedding App busca resolver esto con una sola plataforma, simple y elegante.

## 3. Visión end game del producto

La visión final del producto es que cada matrimonio tenga su propio espacio digital privado, donde:
- cada invitado recibe un acceso único,
- entra a una experiencia personalizada donde ya está identificado,
- confirma asistencia directamente desde su enlace,
- puede informar si asistirá con acompañante,
- puede declarar restricciones alimentarias,
- ve la información del evento y los mensajes de los novios,
- durante el matrimonio puede seguir avisos activos y participar con fotos,
- después puede revivir el evento a través de un álbum final y mensajes de cierre.

La experiencia debe contemplar **URLs compartibles** (`eventapp.com/{id_boda}/{id_invitación}` como punto de entrada y `.../invite` para RSVP), **invitación por WhatsApp** cuando el invitado tiene **teléfono**, y **mesa** y **mapas** como parte de la información oficial.

Además, el producto contempla módulos sociales opcionales —como el módulo solteros— que expanden la experiencia, pero no definen el corazón del producto.

El centro del producto siempre es el matrimonio.

## 4. Principios del producto

### 4.1 Un matrimonio, un mundo privado

Cada evento vive en su propio contexto.
No es una red social entre bodas ni una plataforma abierta entre eventos.

### 4.2 Los novios controlan la verdad oficial

Toda la información importante del matrimonio debe estar centralizada y ser administrada por los novios o por personas autorizadas por ellos.

### 4.3 Cada invitado debe sentirse esperado

El acceso no debe ser genérico.
La app debe reconocer al invitado y darle una experiencia que se sienta personal.

### 4.4 La experiencia debe funcionar antes, durante y después

El valor no termina en la confirmación ni empieza solo en la fiesta.
Debe acompañar todo el ciclo del evento.

### 4.5 Lo social es un complemento, no el núcleo

La capa social puede ser muy valiosa, pero debe estar encapsulada y nunca opacar el propósito principal del producto.

### 4.6 El producto debe sentirse elegante y emocional

No se trata solo de resolver logística. También debe sentirse especial, cálido y acorde a la importancia del evento.

## 5. Usuarios y roles

### 5.1 Novios / organizadores

Son quienes crean el evento y administran su contenido y operación.

Pueden:
- configurar la información del matrimonio,
- cargar y gestionar invitados,
- asignar mesa a cada invitado (y gestionar la lógica del +1 en relación a la mesa),
- definir reglas de asistencia,
- revisar confirmaciones,
- publicar avisos,
- enviar invitaciones por WhatsApp cuando el invitado tiene teléfono registrado (API de WhatsApp),
- operar módulos del evento.

### 5.2 Invitados

Son quienes reciben acceso al evento y lo viven desde una experiencia personalizada.

Pueden:
- acceder al evento desde su enlace,
- confirmar o rechazar su asistencia (y la del acompañante cuando corresponde, como flujo propio),
- informar acompañante si corresponde,
- informar restricciones alimentarias,
- ver su mesa cuando los novios la asignaron,
- consumir información del matrimonio (incluida la ubicación en texto con acceso a mapas),
- participar en funciones habilitadas por el release correspondiente.

### 5.3 Invitados en módulo social opt-in

Son invitados que, voluntariamente, eligen participar en ciertos espacios sociales del evento, como el módulo solteros.

## 6. Cómo funciona el núcleo del producto

### 6.1 Carga de invitados

Los novios deben poder cargar una lista de invitados al evento.

Cada invitado tiene un registro individual con atributos como:
- nombre,
- apellido o nombre visible,
- contacto,
- teléfono (opcional; habilita envío de invitación por WhatsApp vía API),
- estado de invitación,
- si puede o no llevar acompañante,
- si el acompañante tiene nombre definido o no,
- estado de confirmación,
- restricciones alimentarias,
- observaciones relevantes.

La app debe permitir distintos tipos de invitado:

- **Invitado individual sin +1**  
  Ejemplo: “Matías Navarrete”

- **Invitado individual con +1 abierto**  
  Ejemplo: “Matías Navarrete + acompañante”

- **Invitado con acompañante nominal**  
  Ejemplo: “Matías Navarrete y Catalina Pérez”

- **Invitación familiar o grupal**  
  Esto podría venir más adelante, pero la arquitectura ideal debe contemplarlo.

### 6.2 Link único por invitado

Cada invitado debe recibir un enlace único de acceso.

El formato público de la URL debe ser predecible y compartible, por ejemplo:

`https://eventapp.com/{id_boda}/{id_invitación}` (lista de pendientes e información personal) y, para confirmar o rechazar con el contexto del evento, `https://eventapp.com/{id_boda}/{id_invitación}/invite`.

Donde `id_boda` es el slug público del evento e `id_invitación` es el token único del invitado.

**Menú del matrimonio (compartido):** `https://eventapp.com/{id_boda}` — hub del evento; el invitado puede enlazarse con `?invite={id_invitación}` para atajos personalizados.

**Compatibilidad:** enlaces antiguos bajo `/{id_boda}/invite/{id_invitación}` pueden redirigir al checklist `/{id_boda}/{id_invitación}`.

Ese enlace cumple una función clave:
- identifica al invitado,
- evita fricción de login inicial,
- permite abrir una experiencia personalizada,
- sirve como puerta de entrada principal al evento.

Cuando el invitado entra por ese link, la app ya debe saber quién es o, al menos, a qué invitación corresponde.

La experiencia ideal es:
- el invitado abre el enlace,
- la app lo recibe por su nombre,
- le muestra el matrimonio al que está invitado,
- le presenta el estado de su invitación,
- y le pide confirmar o rechazar asistencia.

Esto es central en la propuesta de valor.
No debe sentirse como un formulario frío, sino como una entrada cuidada al evento.

Si el invitado tiene **teléfono registrado**, los novios (o el sistema según reglas del producto) pueden **enviar el mensaje de invitación al matrimonio por WhatsApp** usando la **API de WhatsApp**, con el enlace único del invitado, para reducir fricción y llegar al canal donde ya conversan.

### 6.3 Confirmación de asistencia

La confirmación de asistencia es uno de los corazones del producto.

Desde su enlace único, el invitado principal puede:
- confirmar asistencia,
- rechazar asistencia.

Si la invitación incluye **+1**, el **acompañante no es solo un dato del invitado principal**: debe existir **confirmación o rechazo explícito para el +1** (el acompañante confirma o rechaza su propia asistencia en el flujo, acorde al modelo de invitación: +1 abierto, nominal, etc.).

Sobre el **nombre del +1** cuando aún no está definido o es abierto:
- si el invitado confirma que irá con +1 **sin nombre**, la experiencia debe ofrecir **en el momento** la opción de **ingresar el nombre del acompañante o omitirlo**;
- si **omite** el nombre en ese paso, al **volver a ingresar** a la página del evento debe poder **completar el nombre del +1** cuando corresponda.

Si existen restricciones alimentarias, la experiencia debe capturarlas en este mismo flujo o inmediatamente después (para invitado principal y, si aplica, para el +1 según reglas del evento).

La confirmación no debe sentirse separada del evento.
Debe sentirse integrada a la experiencia del matrimonio.

### 6.4 Gestión manual por parte de los novios

Los novios no solo deben esperar respuestas de invitados.
También deben poder operar manualmente la lista.

Necesitan poder:
- confirmar invitados manualmente,
- marcar invitados como rechazados,
- editar respuestas,
- agregar invitados nuevos,
- eliminar invitados,
- cambiar si alguien tiene o no derecho a +1,
- definir si ese +1 es abierto o nominal,
- asignar o corregir **mesa** por invitado (y coherencia con +1),
- actualizar el nombre del invitado o del acompañante,
- corregir errores operativos.

Esto es fundamental porque en la realidad de los matrimonios siempre hay excepciones, cambios, llamados, confirmaciones por fuera del sistema y ajustes de última hora.

El producto debe abrazar esa realidad.

## 7. Feature: módulo solteros

Este documento debe describirla claramente, así que acá va bien aterrizada.

### 7.1 Qué es

El módulo solteros es una funcionalidad opcional del evento que permite que invitados solteros —o invitados que quieran participar de esa experiencia social— puedan identificarse dentro de un espacio especial del matrimonio.

No busca redefinir el producto como una app de citas.
Busca ofrecer una dinámica social adicional, divertida y privada, acotada exclusivamente a ese matrimonio.

### 7.2 Principio estratégico

El módulo solteros no vende el producto.
No es el corazón de Wedding App.
Debe ser un extra opcional, encapsulado y claramente secundario frente a la experiencia principal del matrimonio.

### 7.3 Cómo funciona conceptualmente

Dentro de un evento determinado, puede existir una experiencia social especial donde ciertos invitados pueden optar por participar.

Al hacerlo, pasan a formar parte de un espacio del evento donde pueden:
- ser visibles en una lista de participantes del módulo,
- acceder a un espacio social o de interacción,
- eventualmente participar en conversaciones, dinámicas o conexiones entre otros invitados que también optaron por entrar.

### 7.4 Participación opt-in

Nadie debe quedar dentro del módulo automáticamente.
La participación debe ser voluntaria y explícita.

Eso significa que:
- el invitado ve que la funcionalidad existe,
- entiende qué implica,
- y decide conscientemente si quiere participar.

### 7.5 Encapsulamiento

El módulo debe vivir en un espacio propio, no mezclado con el flujo principal del matrimonio.

Alguien que no quiera interactuar con esa experiencia no debería sentir que el producto gira en torno a eso.

### 7.6 Evolución por releases

En releases tempranos puede existir solo como una idea preparada o una experiencia muy simple.
En releases posteriores puede expandirse con:
- lista de participantes,
- espacios de conversación,
- interacciones privadas,
- otras dinámicas sociales.

## 8. Estructura del producto por momentos

El producto completo debe pensarse en tres momentos:

### Antes del matrimonio

- invitación,
- reconocimiento del invitado,
- confirmación,
- acompañante,
- restricciones,
- detalles logísticos,
- mensajes previos.

### Durante el matrimonio

- avisos activos,
- experiencia viva del evento,
- fotos,
- mesa,
- interacciones,
- módulos opcionales.

### Después del matrimonio

- álbum final,
- mensajes de agradecimiento,
- recuerdos curados,
- cierre emocional del evento.

Esto es importante porque los releases deben apoyar esta progresión.

## 9. Roadmap por releases

Ahora sí, la división principal.

La lógica será:
- Release 1: producto sólido y valioso por sí solo, centrado en invitación, gestión y experiencia base del matrimonio.
- Release 2: producto expandido hacia experiencia viva del evento y participación visual.
- Release 3: producto premium y distintivo, con componentes experienciales y sociales más avanzados.

## 10. Release 1

### 10.1 Objetivo del Release 1

Lanzar una primera versión del producto que, por sí sola, ya sea una gran solución para organizar e invitar a un matrimonio de forma moderna, elegante y personalizada.

El Release 1 debe resolver muy bien:
- la administración del evento por parte de los novios,
- la carga y gestión de invitados,
- el acceso personalizado por enlace único con URL clara (`eventapp.com/{id_boda}/{id_invitación}` y flujo RSVP en `/invite`),
- la confirmación de asistencia (incluida la del +1 cuando aplica),
- el manejo de +1 con reglas de nombre y confirmación explícita del acompañante,
- la asignación de mesa para invitados y visibilidad para el invitado,
- el manejo de restricciones alimentarias,
- la publicación de información oficial (ubicación en texto y acceso a mapas),
- la comunicación de avisos de los novios,
- el envío de invitaciones por WhatsApp (API) cuando hay teléfono registrado.

Si este release funciona bien, ya hay un producto valioso, completo y comercializable.

### 10.2 Experiencia detallada Release 1

Para que el Release 1 sea un producto de alta calidad, la experiencia se divide en los siguientes flujos críticos:

#### A. Flujo de creación y configuración (Novios)

Es el primer contacto del administrador con la herramienta. Debe ser guiado y profesional.

**Pasos del flujo:**

1. **Identificación del matrimonio:** Los novios definen el nombre del evento (ej: "Matrimonio Catalina y Matías").
2. **Configuración logística:** 
   - Definen **fecha y horario**.
   - Ingresan la **ubicación en texto** (dirección exacta y referencias).
   - Configuran los **puntos geográficos** para habilitar los botones de **Waze** y **Google Maps**.
3. **Información de valor:** 
   - Cargan la **lista de regalos** (link externo o datos bancarios).
   - Redactan el **mensaje de bienvenida** o invitación oficial que verá el invitado al abrir su link.
4. **Personalización visual:** Carga de una imagen de portada o elementos que den identidad al evento.

#### B. Flujo de gestión de invitados y convocatoria (Novios)

Una vez configurado el evento, los novios preparan su lista.

**Pasos del flujo:**

1. **Carga de invitados:** Pueden agregar invitados uno a uno o mediante una carga masiva simple (nombre, contacto, teléfono).
2. **Configuración de reglas por invitado:**
   - Definen si el invitado tiene derecho a **+1**.
   - Indican si el +1 es **nominal** (ya tiene nombre) o **abierto**.
   - Asignan la **mesa** (puede ser antes o después de la confirmación).
3. **Lanzamiento de invitaciones:**
   - El sistema genera automáticamente la URL única del invitado: `eventapp.com/{id_boda}/{id_invitación}` (y la ruta de RSVP `.../invite`).
   - Para invitados con teléfono registrado, los novios disparan el mensaje vía **API de WhatsApp**. El mensaje incluye un texto cálido y el enlace directo.

#### C. Flujo de aterrizaje y reconocimiento (Invitado)

La experiencia del invitado empieza cuando hace clic en su enlace personalizado.

**Pasos del flujo:**

1. **Reconocimiento inmediato:** La página abre saludando al invitado por su nombre (ej: "¡Hola Matías!"). No hay login ni formularios de entrada.
2. **Primer impacto:** Ve la cuenta regresiva, el mensaje de los novios y la información básica (fecha y lugar).
3. **Estado de invitación:** Se le presenta su situación actual ("Aún no has confirmado tu asistencia") con un llamado a la acción (CTA) claro.

#### D. Flujo de confirmación e información (Invitado)

Es el proceso central de captura de datos.

**Pasos del flujo:**

1. **Decisión principal:** Confirmar o Rechazar.
2. **Gestión de acompañante (si aplica):**
   - Si el invitado tiene +1, el sistema pregunta: "¿Asistirás con [Nombre Acompañante]?" o "¿Vendrás con alguien?".
   - El **acompañante debe confirmar o rechazar** explícitamente.
   - Si el nombre del +1 no existe, el invitado puede **ingresarlo en ese momento** o **posponerlo**.
3. **Preferencias alimentarias:** El sistema solicita restricciones (celíaco, vegano, alergias) tanto para el invitado principal como para el +1 confirmado.
4. **Cierre del flujo:** Mensaje de éxito y acceso total a la información del matrimonio.

#### E. Experiencia post-confirmación (Invitado)

Una vez confirmado, el invitado usa la app como su guía oficial.

**Capacidades:**

- **Mesa:** Consulta su número de mesa asignado.
- **Navegación:** Botones activos para abrir la ubicación en **Waze** o **Google Maps** con un toque.
- **Avisos:** Visualiza el feed de avisos oficiales (ej: "Recuerden que hay transporte a las 18:00").
- **Actualización de datos:** Si dejó el nombre del +1 pendiente, puede volver a entrar y completarlo en cualquier momento antes del evento.

#### F. Monitoreo y operación manual (Novios)

El panel de control permite a los novios reaccionar a la realidad del evento.

**Capacidades:**

- **Dashboard de confirmaciones:** Gráfico simple de confirmados, rechazados y pendientes (incluyendo conteo de +1).
- **Operación manual:** Pueden editar cualquier dato de un invitado si este llama por teléfono (cambiar mesa, editar nombre de acompañante, marcar asistencia manual).
- **Filtros operativos:** Lista rápida de restricciones alimentarias para entregar al catering.
- **Gestión de avisos:** Publicación y edición de avisos de último minuto que aparecen en la app de todos los invitados.

### 10.3 Qué no incluye Release 1

Para cuidar foco, Release 1 no debe incluir todavía:
- galería de fotos en vivo,
- muro de fotos,
- ampliación de imágenes,
- check-in de llegada,
- álbum final,
- mensajes de agradecimiento,
- módulo solteros activo,
- chat entre invitados,
- proyección en pantallas.

### 10.4 Por qué Release 1 está bien pensado

Porque resuelve el núcleo más importante del matrimonio:
- invitar,
- reconocer,
- confirmar,
- ordenar,
- comunicar,
- ubicar (texto + mapas),
- distribuir (link y WhatsApp cuando aplica).

Eso ya es un problema enorme y muy valioso.

## 11. Release 2

### 11.1 Objetivo del Release 2

Expandir el producto desde la invitación y organización hacia la experiencia viva del evento.

Si Release 1 resuelve:
- quién está invitado,
- quién viene,
- bajo qué condiciones,

Release 2 resuelve:
- cómo se vive el matrimonio dentro de la app.

### 11.2 Qué incluye Release 2
#### A. Galería de fotos del evento

Los invitados pueden subir fotos al matrimonio.


**Objetivo**


Transformar la app en un espacio vivo, donde el evento empieza a aparecer dentro de la experiencia digital.

#### B. Miniaturas en pantalla principal

La home del evento muestra fotos recientes en miniatura.


**Efecto**


La app ya no solo informa.
Ahora también muestra lo que está pasando.

#### C. Muro de fotos

Existe una vista dedicada con todas las fotos del matrimonio.


**Comportamiento esperado**

- navegación por fotos,
- orden visual claro,
- acceso desde home o sección específica.

#### D. Vista ampliada de fotos

Al tocar una foto, esta se abre en grande.


**Valor**


Hace que la experiencia visual sea más rica y más propia de un evento emocional.

#### E. Mesa en contexto del evento en vivo

En Release 1 el invitado **ya tiene mesa asignada y visible** cuando los novios la definieron. En Release 2 la mesa se **refuerza en el momento del evento**: por ejemplo recordatorios en la home, combinación con **avisos activos** o cualquier ayuda para ubicarse en el salón, según evolucione el producto.

**Valor**

Que la mesa no sea solo un dato previo, sino información útil **cuando** el invitado la necesita.

#### F. Avisos activos

Los avisos evolucionan hacia un concepto más vivo.

Puede haber:

- aviso destacado,
- aviso temporal,
- aviso del momento.

Ejemplo:
- “La ceremonia comienza en 10 minutos”
- “Ya está abierto el cocktail”
- “La fiesta continúa en el salón principal”

#### G. Check-in / ya llegué

El invitado puede indicar que llegó al evento.


**Valor**


Da más sensación de experiencia viva y puede ayudar a coordinación.

#### H. Mensaje de agradecimiento

Una vez terminado el evento, los novios pueden dejar un mensaje de cierre para todos los invitados.


**Valor**


Abre el ciclo “después del matrimonio”.

#### I. Álbum final simple

Los novios pueden dejar una selección básica de fotos destacadas del matrimonio.


**Objetivo**


Evitar que la experiencia muera apenas se acaba el evento.

### 11.3 Qué no incluye Release 2

Todavía dejaría fuera:
- proyección en vivo en pantallas,
- carrusel estilo AirPlay,
- módulo solteros completo,
- chat grupal complejo,
- mensajes directos entre invitados,
- experiencias sociales avanzadas.

## 12. Release 3

### 12.1 Objetivo del Release 3

Llevar Wedding App a una categoría claramente diferenciada y premium.

Release 3 no solo agrega funciones.
Agrega magia.
Hace que el producto se sienta inolvidable.

### 12.2 Qué incluye Release 3
#### A. Proyección en vivo / modo pantalla

Existe una URL especial pensada para ser abierta en una pantalla o proyector del salón.


**Cómo funciona**

- muestra fotos subidas por invitados,
- las va rotando automáticamente,
- se actualiza en tiempo real,
- puede vivir como una presentación visual permanente del evento.

**Valor**


Las fotos ya no solo se guardan: pasan a formar parte del matrimonio en vivo.

#### B. AirPlay Proyectado

Versión más sofisticada de la experiencia de pantalla.


**Concepto**


Las fotos subidas aparecen en tiempo real en las pantallas del salón.

Esto transforma la galería en parte de la atmósfera del evento.

#### C. Álbum final avanzado

Los novios pueden construir una experiencia postevento más curada.

Puede incluir:

- selección destacada,
- portada,
- organización por momentos,
- mejores recuerdos,
- experiencia más editorial.

#### D. Modo “revive el matrimonio”

Una experiencia pensada para consumir el evento después.

Puede incluir:

- mensaje final,
- mejores fotos,
- álbum ordenado,
- cierre emocional del matrimonio.

#### E. Módulo solteros activo

Recién aquí pondría el módulo solteros como experiencia completa.

Y lo describiría así:

**Qué habilita**

Los invitados que quieran participar pueden activar voluntariamente el modo.

Al activarlo:

- pasan a formar parte de la lista del módulo,
- pueden ver a otros participantes del mismo espacio,
- acceden a una experiencia social adicional dentro del evento.

**Posibles capacidades**

- lista de participantes,
- espacio grupal,
- interacciones entre participantes,
- otras dinámicas definidas por producto.

**Restricciones conceptuales**

- solo aplica dentro de ese matrimonio,
- solo para quienes optan por participar,
- no interfiere con la experiencia principal del evento,
- no debe contaminar la percepción premium del producto.

#### F. Canales sociales opcionales

Aquí también pueden entrar otras dinámicas optativas:
- grupos temáticos,
- espacios sociales,
- canales de conversación acotados.

Siempre encapsulados.

## 13. Experiencia completa por usuario

### 13.1 Novios en Release 1

- crean el evento,
- cargan información oficial (ubicación en texto y enlaces a mapas),
- cargan invitados (con teléfono opcional para WhatsApp),
- definen si cada invitado tiene +1 o no,
- definen si ese +1 es nominal o abierto,
- **asignan mesa** por invitado cuando corresponde,
- distribuyen links únicos con URL tipo `eventapp.com/{id_boda}/{id_invitación}`,
- envían invitación por **WhatsApp** (API) cuando hay teléfono,
- reciben confirmaciones (invitado principal y +1 cuando aplica),
- revisan restricciones,
- corrigen manualmente estados,
- publican avisos.

### 13.2 Invitados en Release 1

- reciben su link (mismo esquema de URL),
- entran ya reconocidos,
- ven el matrimonio,
- confirman o rechazan (y el **+1 confirma o rechaza** de forma explícita cuando aplica),
- completan nombre del +1 al tiro o en una visita posterior,
- informan restricciones,
- usan **Waze** / **Google Maps** desde la ficha del evento,
- ven su **mesa** si está asignada,
- acceden a la información del evento,
- consultan avisos de los novios.

### 13.3 Novios en Release 2

Además de lo anterior:
- reciben fotos,
- publican avisos activos,
- ajustan mesa u operación de último momento si el producto lo permite,
- dejan mensaje de agradecimiento,
- cierran con álbum simple.

### 13.4 Invitados en Release 2

Además de lo anterior:
- suben fotos,
- ven miniaturas recientes,
- entran al muro,
- abren fotos en grande,
- viven la **mesa en contexto del evento** (refuerzo el día del evento),
- pueden marcar llegada.

### 13.5 Novios en Release 3

Además de todo:
- proyectan el contenido del evento,
- curan el cierre final,
- habilitan experiencias sociales avanzadas si lo desean.

### 13.6 Invitados en Release 3

Además de todo:
- ven sus fotos formar parte del salón,
- pueden participar en módulos sociales opcionales,
- reviven el evento post matrimonio.

## 14. Por qué este orden de releases tiene sentido

### Release 1

Construye la base real del producto:
- invitación,
- operación,
- confirmación,
- personalización.

### Release 2

Le da vida al evento:
- fotos,
- mesa en contexto del evento en vivo (sobre la base de R1),
- avisos activos,
- agradecimiento,
- recuerdo inicial.

### Release 3

Le da diferenciación fuerte:
- proyección,
- wow factor,
- capa social avanzada,
- experiencia postevento premium.

Es un orden correcto porque primero resuelve lo esencial, luego lo vivo y después lo memorable.

## 15. Riesgos de producto a cuidar

### 15.1 Querer meter demasiadas cosas en Release 1

El riesgo más grande es sobrecargar el primer release.

Release 1 tiene que ser excelente en:
- gestión de invitados,
- links únicos y URL claras,
- confirmación (y reglas del +1),
- mesa,
- restricciones,
- avisos,
- ubicación y mapas,
- WhatsApp cuando hay teléfono.

Si eso sale impecable, ya hay producto.

### 15.2 Que el módulo solteros distorsione la identidad del producto

Si se comunica demasiado pronto o demasiado fuerte, puede generar ruido.

Debe existir, pero encapsulado y tardío en el roadmap.

### 15.3 Que las fotos entren antes de tener resuelto el núcleo de invitación

Las fotos son muy potentes, pero la identidad del producto se funda primero en la experiencia personalizada del invitado.

## 16. Resumen ejecutivo final

### Qué es Wedding App

La app privada del matrimonio: todo lo importante del gran día, en un solo lugar.


### Qué resuelve

Centraliza invitación, confirmación (incluida la del +1 cuando aplica), organización, **mesa**, comunicación (incluido **WhatsApp** con teléfono registrado), **ubicación** en texto con acceso a **Waze** y **Google Maps**, y recuerdos en una sola experiencia.


### Cómo crece el producto

#### Release 1

La base sólida del producto:

- evento,
- invitados,
- links únicos (`eventapp.com/{id_boda}/{id_invitación}` + RSVP en `/invite`),
- confirmación (principal y +1),
- +1 con nombre al tiro o después,
- mesa asignada y visible,
- ubicación en texto + Waze / Google Maps,
- restricciones,
- avisos,
- WhatsApp (API) si hay teléfono,
- gestión operativa por novios.

#### Release 2

La experiencia viva del matrimonio:

- fotos,
- miniaturas,
- muro,
- vista ampliada,
- refuerzo de mesa el día del evento,
- avisos activos,
- check-in,
- agradecimiento,
- álbum simple.

#### Release 3

La experiencia premium y memorable:

- proyección en vivo,
- AirPlay visual del salón,
- álbum avanzado,
- revive el evento,
- módulo solteros,
- capa social opcional.

## 17. Recomendación importante sobre Release 1

Te lo marco porque dijiste “piensa muy bien los release y sobre todo el 1”.

La calidad del producto se juega mucho en Release 1.
Y Release 1 no debe intentar “verse impresionante” por cantidad de features.

Debe verse impresionante por:
- claridad,
- elegancia,
- personalización,
- solidez operativa.

Si Release 1 logra que:
- los novios carguen invitados fácilmente,
- definan +1 correctamente,
- cada invitado reciba un link único,
- entre reconocido,
- confirme sin fricción,
- y los novios tengan control real sobre estados y cambios,

entonces ya tienes una primera versión muy fuerte, con muchísimo valor y con una identidad clara.
