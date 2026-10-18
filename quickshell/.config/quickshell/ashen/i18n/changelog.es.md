# Cambios

Traducción de las notas de CHANGELOG.md. Solo hace falta la versión actual:
si falta, la bienvenida las enseña en inglés.

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
