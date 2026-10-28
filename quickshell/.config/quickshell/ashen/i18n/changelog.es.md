# Cambios

Traducción de las notas de CHANGELOG.md. Solo hace falta la versión actual:
si falta, la bienvenida las enseña en inglés.

## 3.7.0

### Añadido
- **Colgada**, un estilo de barra: un plato colgado del borde de la
  pantalla, recto donde lo toca, redondeado hacia dentro, y el borde
  curvándose hacia sus dos extremos. Respeta el ajuste de longitud.
- **Acomodar ventanas con el teclado.** `SUPER+SHIFT+flechas` mueve una
  ventana (entrando y saliendo de grupos), `SUPER+J`/`SUPER+K` giran e
  intercambian una división, `SUPER+R` pasa la ventana por 1/3, 1/2 y 2/3, y
  `SUPER+CTRL+P` la fija en todos los escritorios.
- **Pestañas**: `SUPER+G` agrupa ventanas en pestañas, `SUPER+Tab` y
  `SUPER+SHIFT+Tab` las recorren. La barra de pestañas lleva el acento del
  fondo.
- **Columnas**: `SUPER+SHIFT+L` cambia el escritorio entre mosaico y la
  distribución en columnas, hasta que Hyprland recarga.
- Las ventanas flotantes se pegan a los bordes y entre sí.
- **Tooltips** en los botones de solo icono, tras una pausa breve, y una
  onda desde donde pulsas.
- **Indicador de privacidad**: una píldora que enseña el micrófono, la
  cámara y la pantalla mientras algo los usa, y se va al soltarlos.
- **Esquinas de pantalla redondeadas**, en Ajustes > Pantalla.
- `ashen rollback` vuelve a donde empezó el último `ashen update`.
- **Límites diarios** en el panel de tiempo de pantalla: el reloj de arena
  de la fila de una app pasa por 30 min, 1, 2 y 3 horas. Avisa cinco
  minutos antes y al llegar.
- **Hooks**: un ejecutable en `~/.config/ashen/hooks/<evento>` corre al
  arrancar y con wallpaper, lock, unlock, theme, power, battery-low, usb y
  game. Más en el README.
- **Teclas en los paneles**: Escape los cierra; las flechas cambian el
  volumen, el día o la pista, Espacio reproduce y pausa, M silencia, y
  `Ctrl+Tab` recorre las pestañas de Ajustes.

### Cambiado
- `SUPER+SHIFT+F` flota una ventana centrada al 60 % por 70 % de la
  pantalla, quitándole antes el maximizado.
- El panel de tiempo de pantalla habla el idioma del panel del reloj: sin
  platos, líneas finas entre secciones, filas de apps como el widget y una
  curva por horas escalada a la hora más ocupada. Cambiar de día se corre
  hacia donde te moviste y luego crecen la curva y las barras; una semana
  nueva sube todas las barras, un día nuevo solo la suya.
- El estilo blur es más cristal: un velo más fino en barra, paneles,
  píldoras y widgets, y un blur del compositor que ya no oscurece lo de
  detrás (ventanas incluidas).
- Ajustes > Red son tarjetas, como el resto de Ajustes; la contraseña se
  abre bajo su red en vez de tapar la página.
- La barra de edición del escritorio son iconos con el modo elegido
  nombrado, y el selector de widgets va agrupado, con una marca en vez de
  relleno de acento.
- El selector de fondos abre en la mitad de tiempo.
- El progreso de la música es una onda que avanza mientras suena y se
  aplana en pausa.
- Las ventanas abren y se mueven con un muelle que se asienta; el
  escritorio especial atenúa lo de detrás.
- Tus distribuciones de teclado y el color del borde de ventana se guardan
  en `~/.config/ashen/hypr/`, fuera del repo, y un `user.lua` ahí recibe tu
  propia configuración de Hyprland, cargada al final. Las actualizaciones ya
  no chocan con ellos.
- El estilo de iconos de los escritorios va sin losetas: el icono de la app,
  el escritorio en el que estás en el acento, y uno vacío es un punto.

### Arreglado
- Los iconos de las apps en el dock, Ajustes y el lanzador se ven nítidos;
  salían pixelados, y más borrosos al crecer en el dock con el puntero.
- Un agente de polkit arranca con la sesión; las apps que pedían root no
  tenían quién preguntara.
- Los puertos virtuales de Docker ya no salen en el panel de Ethernet.
- El indicador de volumen y brillo salía recortado con la barra a la
  derecha, y parpadeaba al irse.
- Los ajustes se guardan de una vez; un cierre a mitad de guardado ya no
  los deja vacíos.
- El clima de una ciudad con apóstrofo en el nombre (L'Aquila).
- Una clase de ventana o una notificación con comillas podía ejecutar
  órdenes desde el dock o la acción de enfocar de la notificación.
- El indicador de cámara y la distribución del teclado gastan menos en
  reposo.

## 3.6.0

### Añadido
- **El dock lleva más que aplicaciones.** Ajustes > Escritorio > Dock pone
  en él píldoras de la barra como iconos -- sonido, batería, el reloj,
  notificaciones y el resto, cada una haciendo lo que hace su píldora -- y
  atajos: bloquear, fondos, ajustes, procesos, ordenar widgets, modo juego,
  luz nocturna, o un comando tuyo con su glifo. Cada grupo va antes o
  después de las apps. Clic derecho quita uno,
  igual que desancla una app.
- **Acoplada**, un estilo de barra: pegada a todo el borde, sin aire
  alrededor, y la pantalla curvándose hacia ella en los dos extremos.
- Cositas que pulsar en los widgets, en el escritorio y en la pantalla de
  bloqueo: la tarjeta de música despliega la línea que se está cantando, la
  de notificaciones se abre para enseñar más (o un dibujito de píxeles
  cuando no hay nada), y acercarse a la tarjeta de la máquina enseña la
  batería y cuánto le queda. El widget de música completo abre su letra al
  lado.
- Los resultados de la búsqueda de Ajustes llevan el icono de su sección, y
  dicen dónde viven cuando dos se llaman igual.
- **El comando `ashen`**: `update`, `check`, `version`, `restart`, `doctor`,
  `logs`, `wallpaper next|prev|random|<archivo>`, `bar …` e `ipc …`, con
  autocompletado en zsh (`ashen help`).
- Un toast avisa cuando cambian la distribución del teclado, el idioma del
  shell o la ciudad del clima.

### Cambiado
- **Framed desaparece**; Acoplada ocupa su lugar, y los looks guardados que
  lo usaban cargan como Acoplada.
- Las tarjetas de Ajustes llevan su icono y un título que encabeza las filas
  de debajo.
- El selector de imágenes habla el idioma de los paneles: iconos en
  baldosas, lugares sobre un plato, carpetas como filas.
- La onda de sonido de la barra se dibuja detrás de las ventanas y los
  widgets, y llega más adentro de la pantalla.
- La onda del visualizador y la tira del widget de música son más densas.
- El dock con ocultado automático se hace sitio como la barra.
- La ubicación del clima y las distribuciones de teclado son ahora listas,
  con el buscador de Ajustes debajo: lo que encuentra se despliega en la
  misma caja, Enter toma el primero y si no hay nada lo dice ahí mismo.

### Corregido
- **El shell gastaba un par de por ciento de CPU sin hacer nada.** Escuchaba
  los cambios de perfil de energía con `powerprofilesctl monitor`, un
  comando que las versiones nuevas quitaron: salía al instante y se volvía a
  lanzar varias veces por segundo, sin fin. Ahora el perfil se lee del
  servicio directamente, y en reposo vuelve a quedar muy por debajo del
  medio por ciento.
- **Actualizar ahora actualiza.** El botón ejecutaba el instalador sobre el
  código que ya había y nunca traía la versión nueva; ahora ejecuta
  `ashen update`, que primero descarga.
- Los widgets del escritorio ya no desaparecen detrás de una ventana
  maximizada (no a pantalla completa).
- Arrastrar una app anclada en Ajustes > Escritorio ya no deja una fila rota.
- El hover de la foto de perfil ya no deshilacha su borde redondo.
- El wallpaper de arriba de Aspecto ya no se vuelve a cargar en cada visita.
- El selector de wallpapers, Alt+Tab y el menú de apagado ya no abren ni
  cierran tras un corte recto que los atraviesa; el carrusel del selector se
  desvanece en vez de desaparecer de golpe.
- Reordenar las apps ancladas del dock en Ajustes pedía dos arrastres: la
  lista se quedaba con el orden viejo tras el primero y el siguiente clic
  agarraba otra fila.
- Los widgets que se despliegan (música, notificaciones, la máquina) ya no
  tiemblan en la pantalla de bloqueo ni empujan a saltos las tarjetas de
  debajo: el plato se anima una vez, hasta su tamaño final. Y las columnas
  del bloqueo ya no saltan arriba y abajo mientras una se despliega: la
  altura en la que se apoyan solo se mide con el pliegue quieto.

## 3.5.0

### Añadido
- **Gestos del touchpad y un scratchpad** (ideas del PR #2 de RchrdAriza).
  Tres dedos a los lados siguen cambiando de escritorio; arriba abre el
  lanzador y abajo muestra el scratchpad; cuatro dedos mueven la ventana.
  Viven en `hypr/conf/gestures.lua` y Ajustes > Entrada los lista en una
  tarjeta Gestos. El scratchpad es un escritorio especial como los demás:
  SUPER+S lo muestra, SUPER+ALT+S manda allí la ventana (los dos
  reasignables), y su ficha muestra el icono de la app que contiene.

### Cambiado
- Novedades muestra las tres últimas versiones, cada una bajo su número, no
  solo la actual: una versión pequeña se veía como una página cortada.

### Gracias
- **@RchrdAriza**, por los gestos del touchpad, el scratchpad y su icono
  vivo (PR #2), en los que se basa esta versión.

## 3.4.0

### Añadido
- **Ashen te avisa cuando sale una versión nueva.** Al minuto de iniciar
  sesión y cada seis horas mira la última release en GitHub (nunca un
  commit) y, una vez por versión, muestra un toast -- la versión y una frase
  del banco -- con Actualizar -- lo mismo que Ajustes > Acerca de. Dura el
  doble que los demás toasts y se guarda en el historial de notificaciones
  por si no lo viste. No dice nada sin red, al día o por delante. El
  interruptor está en Ajustes > Acerca de.
- **Elige qué reproductor sigue la tarjeta de música**, como en Caelestia:
  el nombre del reproductor está entre los tiempos, y un clic lista todos con
  lo que suena en cada uno; al elegir, la tarjeta, sus botones, la barra y los
  widgets lo siguen (`qs -c ashen ipc call media source` pasa al siguiente).
  Antes cada superficie tomaba el primero y el otro no se podía pausar. Dos
  pestañas de un navegador siguen siendo un solo reproductor: el navegador
  solo publica la última que sonó.
- **La letra es un widget propio**, ya no una forma del de música: leerla
  costaba el botón de reproducir. Tres formas -- *Página* (la de antes, con
  la portada), *Línea* (la línea que suena y la siguiente, para una esquina)
  y *Foco* (la línea grande en el centro, las de alrededor atenuadas). Un
  escritorio que llevaba la forma de letra recibe el widget de letra en su
  sitio.
- La pantalla de bloqueo muestra la onda de la música en su borde superior, en
  reposo y al iniciar sesión -- la misma que dibuja la barra.
- **El instalador pregunta tres cosas primero**, con las flechas: el idioma
  del shell, la distribución del teclado (también llega a la pantalla de
  inicio de sesión) y el idioma del sistema (`locale-gen` + `localectl`;
  mantener el actual es lo predeterminado). `ASHEN_LANG`, `ASHEN_KB` y
  `ASHEN_LOCALE` saltan cada pregunta.
- La bienvenida y las notas de versión salen en tu idioma: las de español,
  alemán y ruso viven en `i18n/changelog.<idioma>.md`; si no, en inglés.

### Cambiado
- **El panel de USB, rehecho.** Una tarjeta por memoria con sus particiones
  dentro, en vez de una por partición con un botón de expulsar cada una. Cada
  partición tiene abrir carpeta y montar/desmontar, y una barra con lo libre
  una vez montada; la memoria tiene Expulsar, que desmonta todo y la apaga.
  Cada acción espera su respuesta y la dice: "Ya puedes retirar Ventoy", o
  que está en uso. También aparecen los discos USB externos.
  `qs -c ashen ipc call usb toggle|state`.
- **Los paneles se abren en un solo movimiento desde su píldora.** En el
  estilo transformación un panel ya no cae de la barra colgado de un hilo: se
  estira desde su píldora y se queda pegado a ella, con el color de la barra,
  así que se lee como la barra creciendo. Al cerrar se posa suave sobre la
  píldora, que reaparece cuando llega la caja. Funciona con la barra en
  cualquier borde. `qs -c ashen ipc call panels style morph|plain` lo cambia.
- Las apps ancladas al dock se ordenan arrastrándolas (Ajustes > Escritorio
  > Dock), y se quitan soltándolas en la zona que ocupa el sitio del buscador
  mientras arrastras. Sin flechas.
- **System empieza por ti**: tu foto en grande sobre tu fondo, difuminado,
  con tu nombre y un botón para cambiarla.
- **Inactividad y suspensión** se lee de un vistazo: un deslizador por
  temporizador con su icono, *nunca* a la izquierda del todo. Nuevo: qué hace
  cerrar la tapa -- *Suspender*, *Solo bloquear* o *Nada*. Las dos últimas
  impiden la suspensión mientras el shell esté en marcha.
- El widget de música es el de los botones: *Completo* y *Compacto*. Su
  *Onda* pasó al visualizador, que dibujaba el mismo sonido, y ocupa el lugar
  de sus *Barras*. Un escritorio que llevaba cualquiera de las dos recibe la
  onda en el visualizador.
- **Escritorios.** Contar ventanas ahora es un interruptor para todos los
  estilos en lugar de un estilo propio: Ajustes > Barra > Disposición > Escritorios
  > *Contar ventanas*, o `qs -c ashen ipc call bar ticks`. Los puntos no lo
  usan: las marcas quedarían encima del punto.
- Los escritorios especiales muestran su propio icono (música, discord, notas,
  fav) en todos los estilos salvo kanji, así un punto o un número ya no oculta
  cuál está abierto. En Pac-Man van sin bloque detrás y el abierto se
  convierte en Pac-Man.
- En el estilo de iconos un escritorio vacío muestra un anillo vacío en lugar
  de su número.
- El widget de tiempo de pantalla se parece a los demás widgets: el icono de
  cada aplicación sobre una placa, su tiempo y una barra con su parte del día.
- Más partes del shell hablan tu idioma: la lista de atajos de Ajustes >
  Entrada, los nombres de las píldoras, la bandeja de widgets, sus formas,
  las carpetas del selector y las aplicaciones predeterminadas.

### Arreglado
- Los paneles sin píldora (lanzador, Ajustes, portapapeles, menú de
  apagado) se abren igual cada vez. Empezaban su animación antes de que su
  ventana estuviera en pantalla y perdían un trozo distinto según si la
  ventana era nueva, ya estaba o se estaba cerrando.
- Los paneles sin píldora propia (Ajustes, lanzador, portapapeles, menú de
  apagado, fondos) se abren con el mismo movimiento que el resto: una cápsula
  del tamaño de una píldora aparece donde vive y se estira hasta él, y luego
  el contenido junto -- sin
  desplegarse, sin subir, sin piezas una a una. La vista previa de un
  escritorio crece desde su ficha como los demás paneles, y sus ventanas
  aparecen con el resto en vez de caer una a una. Nace justo sobre la ficha,
  con su color (el acento en la activa), mientras la ficha se aparta como
  cualquier píldora: antes un cuadro oscuro se quedaba quieto sobre la ficha
  un momento y su fondo asomaba alrededor.
- **Los paneles ya no reorganizan sus piezas por el camino.** La píldora se
  apaga, la caja se estira desde ella y el contenido aparece con un fundido
  en su sitio; al cerrar se desvanece primero. Las piezas que volaban se
  rompían en la vista previa y en otros paneles. Y la parte de un panel que
  crece sobre la barra recibe clics: el shell reserva esa franja para las
  píldoras, así que los botones que caían en ella (pestañas Wi-Fi/Ethernet,
  controles de notificaciones) no se podían pulsar.
- El texto de la vista previa de un escritorio es lo que muestra la ficha --
  un kanji, el fantasma de Pac-Man, una app -- no siempre el número.
- Los paneles que crecen desde una píldora mantienen el contenido del lado de
  la barra: centrado, se deslizaba dentro de la caja y se veía cortado al
  cerrar (batería).
- Abrir un panel ya no enciende antes su píldora: el relleno de acento es
  del estilo ventana, donde la píldora se queda en la barra. La de USB solo
  ilumina su icono si hay algo montado, como las demás.
- Wi-Fi, Bluetooth y los demás paneles sobre un plato arrancan en el borde
  del plato, no unos píxeles por dentro. Notificaciones y procesos crecen
  desde su píldora como el resto.
- El instalador cambia un qt6ct del AUR (qt6ct-kde y similares) por el de
  los repositorios. Contaba como instalado, pero solo encaja con la Qt con la
  que se compiló: tras la siguiente actualización de Qt, Qt lo descartaba sin
  avisar y el lanzador y todas las apps Qt perdían los iconos de Papirus.
- La onda del panel de música pisaba el nombre del álbum; la tarjeta es un
  poco más alta.
- El dock oculto ya no desaparece en cuanto el puntero se pasa de sus
  iconos: espera un momento, y volver lo mantiene fuera. La franja vacía a
  sus lados dejó de tragarse los clics de las ventanas de debajo.
  `qs -c ashen ipc call dock autohide` activa o quita el ocultado.
- AM y PM se escriben igual en todos los idiomas: en español salía "p. m.",
  demasiado ancho para la barra y la línea del amanecer.
- **Dos teclados, dos distribuciones.** Hyprland guarda una distribución por
  teclado, y uno que aparecía después (un receptor inalámbrico al despertar,
  un USB, el inicio de sesión) empezaba en la primera mientras el resto
  seguía en la elegida. Ahora todos siguen la elegida, y uno tardío se
  corrige en pocos segundos.
- El instalador fallaba con el cursor: `bibata-cursor-theme` se compila desde
  el código y necesita otro paquete de AUR, así que ahora instala
  `bibata-cursor-theme-bin`. Su línea para reintentar ya no te manda a pedir
  paquetes de AUR a pacman.
- Los widgets del escritorio quedan fuera del interruptor del visualizador:
  apagado, la barra, el panel de música y la pantalla de bloqueo se callan,
  pero los widgets de visualizador y música siguen moviéndose -- cava sigue
  escuchando mientras uno de ellos esté puesto.
- La onda de música de la barra estaba apagada en el estilo isla; ahora se ve
  ahí, entre los platos, igual que entre las píldoras.
- Pac-Man se desliza de escritorio en escritorio como el indicador de los
  demás estilos, en vez de parpadear de una ficha a la siguiente.
- Un fantasma aparece solo donde de verdad hay ventanas: el escritorio que
  acababas de dejar mostraba uno durante un momento.
